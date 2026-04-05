import SwiftUI

// One-time intro shown on first launch only.
// Two pages, each with a headline that types in right-to-left and fades,
// then the whole thing fades out.
struct IntroView: View {
    let onDone: () -> Void

    @State private var page = 0         // 0 or 1
    @State private var visibleChars = 0 // how many chars of headline are shown
    @State private var subtitleOpacity: Double = 0
    @State private var pageOpacity: Double = 1
    @State private var iconScale: CGFloat = 0.7
    @State private var iconOpacity: Double = 0

    private let pages: [(icon: String, headline: String, sub: String)] = [
        (
            icon: "waveform",
            headline: "Music learns you.",
            sub: "Not playlists. Not genres. Sonik listens to the raw sound of every track and builds a taste model that's uniquely yours."
        ),
        (
            icon: "hand.draw",
            headline: "Swipe. Like. Discover.",
            sub: "Every card is a 30-second preview. Swipe right to train your model. Swipe left to skip. The more you swipe, the smarter it gets."
        ),
    ]

    private var current: (icon: String, headline: String, sub: String) {
        pages[page]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "100220"), Color.black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle ambient glow
            Circle()
                .fill(Color(hex: "7c3aed").opacity(0.18))
                .frame(width: 340, height: 340)
                .blur(radius: 80)
                .offset(y: -60)

            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "a855f7").opacity(0.12))
                        .frame(width: 90, height: 90)
                    Image(systemName: current.icon)
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "e9d5ff"), Color(hex: "a855f7")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
                .padding(.bottom, 40)

                // Headline — characters reveal right-to-left
                rtlTypeText(current.headline)
                    .font(.system(size: 34, weight: .bold, design: .default))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
                    .fixedSize(horizontal: false, vertical: true)

                // Subtitle fades in after headline
                Text(current.sub)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(hex: "b084f5").opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 36)
                    .opacity(subtitleOpacity)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                // Page dots + Continue
                VStack(spacing: 28) {
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            Capsule()
                                .fill(i == page
                                      ? Color(hex: "a855f7")
                                      : Color.white.opacity(0.2))
                                .frame(width: i == page ? 20 : 7, height: 7)
                                .animation(.easeInOut(duration: 0.3), value: page)
                        }
                    }

                    Button(action: advance) {
                        Text(page == pages.count - 1 ? "Get Started" : "Continue")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "7c3aed"), Color(hex: "a855f7")],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .padding(.horizontal, 36)
                    }
                }
                .padding(.bottom, 52)
            }
        }
        .opacity(pageOpacity)
        .onAppear { animateIn() }
    }

    // MARK: - Right-to-left type reveal

    func rtlTypeText(_ full: String) -> some View {
        let chars = Array(full)
        let total = chars.count
        // We show chars from the END backward, so chars[(total - visibleChars)...]
        let startIdx = max(0, total - visibleChars)
        let visible  = String(chars[startIdx...])
        // Pad with invisible characters at front so layout stays stable
        let invisible = String(repeating: " ", count: startIdx)
        return Text(invisible + visible)
    }

    // MARK: - Animations

    func animateIn() {
        visibleChars  = 0
        subtitleOpacity = 0
        iconScale     = 0.7
        iconOpacity   = 0

        // Icon pops in
        withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) {
            iconScale   = 1.0
            iconOpacity = 1.0
        }

        // Headline types in right-to-left — one char per 38ms
        let total = pages[page].headline.count
        for i in 1...total {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.038) {
                withAnimation(.linear(duration: 0.03)) { visibleChars = i }
            }
        }

        // Subtitle fades after headline finishes
        let headlineDuration = Double(total) * 0.038 + 0.25
        DispatchQueue.main.asyncAfter(deadline: .now() + headlineDuration) {
            withAnimation(.easeIn(duration: 0.55)) { subtitleOpacity = 1 }
        }
    }

    func advance() {
        if page < pages.count - 1 {
            // Cross-fade to next page
            withAnimation(.easeInOut(duration: 0.35)) { pageOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                page += 1
                withAnimation(.easeInOut(duration: 0.35)) { pageOpacity = 1 }
                animateIn()
            }
        } else {
            // Last page — fade out entirely then call onDone
            withAnimation(.easeInOut(duration: 0.5)) { pageOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onDone() }
        }
    }
}
