import SwiftUI
import AVFoundation

struct SwipeView: View {
    @State private var tracks: [Track] = []
    @State private var currentIndex = 0
    @State private var offset = CGSize.zero
    @State private var player: AVPlayer?
    @State private var loading = true
    @State private var errorMessage: String? = nil
    @State private var searchTerm = "top hits"
    @State private var searchInput = ""
    @State private var showSearch = false

    var currentTrack: Track? {
        guard currentIndex < tracks.count else { return nil }
        return tracks[currentIndex]
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "1a0533"), Color.black],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack {
                // Header
                HStack {
                    Text("Discover")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { showSearch.toggle() }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color(hex: "a855f7"))
                            .font(.system(size: 20))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                if showSearch {
                    HStack {
                        TextField("Search genre or artist...", text: $searchInput)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .onSubmit {
                                searchTerm = searchInput.isEmpty ? "top hits" : searchInput
                                showSearch = false
                                loadTracks()
                            }
                        if !searchInput.isEmpty {
                            Button(action: { searchInput = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                if loading {
                    VStack(spacing: 16) {
                        ProgressView().tint(.white).scaleEffect(1.5)
                        Text("Loading songs...")
                            .foregroundColor(Color(hex: "9d7fc4"))
                            .font(.subheadline)
                        Text("First load can take up to 2 min while the AI wakes up")
                            .foregroundColor(.gray)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else if let err = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "a855f7"))
                        Text(err)
                            .foregroundColor(.white)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        Button(action: loadTracks) {
                            Text("Try Again")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Color(hex: "7c3aed"))
                                .cornerRadius(12)
                        }
                    }
                    .padding(32)
                } else if let track = currentTrack {
                    cardView(track: track)
                        .offset(offset)
                        .rotationEffect(.degrees(Double(offset.width / 20)))
                        .gesture(
                            DragGesture()
                                .onChanged { offset = $0.translation }
                                .onEnded { handleSwipe($0.translation) }
                        )
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: offset)

                    HStack(spacing: 56) {
                        circleButton(icon: "xmark", color: .red) {
                            animateSwipe(direction: "dislike")
                        }
                        circleButton(icon: "heart.fill", color: Color(hex: "a855f7")) {
                            animateSwipe(direction: "like")
                        }
                    }
                    .padding(.top, 28)

                    Text("Each swipe trains your personal taste model")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                        .padding(.top, 12)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "a855f7"))
                        Text("You've heard everything here!")
                            .foregroundColor(.white)
                            .font(.headline)
                        Button(action: loadTracks) {
                            Text("Load More")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Color(hex: "7c3aed"))
                                .cornerRadius(12)
                        }
                    }
                }

                Spacer()
            }
        }
        .onAppear { loadTracks() }
        .animation(.easeInOut, value: showSearch)
    }

    func cardView(track: Track) -> some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(
                    colors: [Color(hex: "2d1060"), Color(hex: "0d0620")],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 320, height: 460)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color(hex: "7c3aed").opacity(0.3), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 10) {
                Text(track.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                Text(track.artist)
                    .foregroundColor(Color(hex: "b084f5"))
                    .font(.subheadline)
                HStack(spacing: 12) {
                    Button(action: togglePlay) {
                        Image(systemName: player?.timeControlStatus == .playing ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                    }
                    Text("30s preview")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            .padding(24)
            .frame(width: 320, alignment: .leading)

            if offset.width > 50 {
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color(hex: "a855f7"), lineWidth: 4)
                    .overlay(
                        Text("LIKE")
                            .font(.system(size: 36, weight: .black))
                            .foregroundColor(Color(hex: "a855f7"))
                            .rotationEffect(.degrees(-15))
                    )
                    .frame(width: 320, height: 460)
                    .opacity(Double(min(offset.width / 100, 1)))
            } else if offset.width < -50 {
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.red, lineWidth: 4)
                    .overlay(
                        Text("NOPE")
                            .font(.system(size: 36, weight: .black))
                            .foregroundColor(.red)
                            .rotationEffect(.degrees(15))
                    )
                    .frame(width: 320, height: 460)
                    .opacity(Double(min(-offset.width / 100, 1)))
            }
        }
    }

    func circleButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundColor(color)
                .frame(width: 68, height: 68)
                .background(color.opacity(0.12))
                .clipShape(Circle())
                .overlay(Circle().stroke(color.opacity(0.25), lineWidth: 1))
        }
    }

    func handleSwipe(_ translation: CGSize) {
        if translation.width > 100 {
            animateSwipe(direction: "like")
        } else if translation.width < -100 {
            animateSwipe(direction: "dislike")
        } else {
            withAnimation(.spring()) { offset = .zero }
        }
    }

    func animateSwipe(direction: String) {
        guard let track = currentTrack else { return }
        withAnimation(.easeOut(duration: 0.3)) {
            offset = CGSize(width: direction == "like" ? 600 : -600, height: 0)
        }
        player?.pause()
        player = nil
        Task { try? await APIService.shared.swipe(trackId: track.id, direction: direction) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            currentIndex += 1
            offset = .zero
        }
    }

    func togglePlay() {
        guard let track = currentTrack else { return }
        if let p = player {
            if p.timeControlStatus == .playing { p.pause() } else { p.play() }
        } else {
            player = AVPlayer(url: URL(string: track.preview_url)!)
            player?.play()
        }
    }

    func loadTracks() {
        loading = true
        errorMessage = nil
        currentIndex = 0
        player?.pause()
        player = nil
        Task {
            do {
                let results = try await APIService.shared.recommendations(searchTerm: searchTerm)
                await MainActor.run {
                    if results.isEmpty {
                        errorMessage = "No songs found. Try a different search."
                    } else {
                        tracks = results
                    }
                    loading = false
                }
            } catch APIError.server(let code) {
                await MainActor.run {
                    errorMessage = "Server error \(code). The AI may be out of memory — tap Try Again."
                    loading = false
                }
            } catch APIError.unauthorized {
                // @AppStorage already cleared the token; ContentView will show login.
                await MainActor.run { loading = false }
            } catch {
                // Likely a timeout — CLAP cold-start can take 90-120s.
                await MainActor.run {
                    errorMessage = "Timed out waiting for AI server. Tap Try Again (it wakes up within 2 min)."
                    loading = false
                }
            }
        }
    }
}
