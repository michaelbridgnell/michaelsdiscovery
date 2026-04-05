import SwiftUI

struct LoadingView: View {
    @State private var pulse = false
    @State private var ringScale: CGFloat = 0.7
    @State private var ringOpacity: Double = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1a0533"), Color.black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                ZStack {
                    // Ripple rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color(hex: "a855f7").opacity(0.25), lineWidth: 1.5)
                            .frame(width: 90, height: 90)
                            .scaleEffect(ringScale + CGFloat(i) * 0.22)
                            .opacity(ringOpacity)
                            .animation(
                                .easeOut(duration: 1.4)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.4),
                                value: ringScale
                            )
                    }

                    // Character centred
                    WalkingGuy()
                        .frame(width: 160, height: 120)
                        .scaleEffect(pulse ? 1.06 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                            value: pulse
                        )
                }

                VStack(spacing: 8) {
                    Text("Sonik")
                        .font(.custom("AvenirNext-Heavy", size: 36))
                        .italic()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "c084fc")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )

                    Text("Building your taste model…")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "9d7fc4"))
                }
                .opacity(textOpacity)

                ProgressView()
                    .tint(Color(hex: "a855f7"))
                    .scaleEffect(1.2)
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            pulse = true
            withAnimation(.easeOut(duration: 0.6)) {
                ringScale = 1.6
                ringOpacity = 1
                textOpacity = 1
            }
        }
    }
}
