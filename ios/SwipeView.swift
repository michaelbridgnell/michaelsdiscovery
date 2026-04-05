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
    @State private var autoplay = true
    @State private var isPlaying = false

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
                    // Autoplay toggle
                    Button(action: { autoplay.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: autoplay ? "play.fill" : "pause.fill")
                                .font(.system(size: 11))
                            Text("Auto")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(autoplay ? Color(hex: "a855f7") : .gray)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(20)
                    }
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
                                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
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
                    VStack(spacing: 24) {
                        WalkingGuy().frame(width: 160, height: 120)
                        Text("Finding tracks for you")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        ProgressView().tint(Color(hex: "a855f7"))
                    }
                } else if let err = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 44, weight: .light))
                            .foregroundColor(Color(hex: "a855f7"))
                        Text(err)
                            .foregroundColor(Color(hex: "b084f5"))
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Button(action: loadTracks) {
                            Text("Try Again")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 32).padding(.vertical, 12)
                                .background(LinearGradient(
                                    colors: [Color(hex: "7c3aed"), Color(hex: "a855f7")],
                                    startPoint: .leading, endPoint: .trailing))
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
                        circleButton(icon: isPlaying ? "pause.fill" : "play.fill",
                                     color: .white) { togglePlay() }
                        circleButton(icon: "heart.fill", color: Color(hex: "a855f7")) {
                            animateSwipe(direction: "like")
                        }
                    }
                    .padding(.top, 20)

                    Text("Each swipe trains your personal taste model")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.top, 8)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "a855f7"))
                        Text("You've heard everything here!")
                            .foregroundColor(.white).font(.headline)
                        Button(action: loadTracks) {
                            Text("Load More")
                                .fontWeight(.bold).foregroundColor(.white)
                                .padding(.horizontal, 32).padding(.vertical, 12)
                                .background(Color(hex: "7c3aed")).cornerRadius(12)
                        }
                    }
                }

                Spacer()
            }
        }
        .onAppear { loadTracks() }
        .animation(.easeInOut, value: showSearch)
        .onChange(of: currentIndex) { _, _ in
            if autoplay { startPlayback() }
        }
    }

    // MARK: - Card

    func cardView(track: Track) -> some View {
        ZStack(alignment: .bottom) {
            // Album art fills the card
            if let urlStr = track.artwork_url, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    if let img = phase.image {
                        img.resizable().aspectRatio(contentMode: .fill)
                            .frame(width: 320, height: 460)
                            .clipped()
                    } else {
                        artPlaceholder
                    }
                }
                .frame(width: 320, height: 460)
                .clipShape(RoundedRectangle(cornerRadius: 28))
            } else {
                artPlaceholder
            }

            // Gradient overlay at bottom for text readability
            LinearGradient(colors: [Color.clear, Color.black.opacity(0.85)],
                           startPoint: .center, endPoint: .bottom)
                .frame(width: 320, height: 460)
                .clipShape(RoundedRectangle(cornerRadius: 28))

            // Track info
            VStack(alignment: .leading, spacing: 6) {
                Text(track.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                Text(track.artist)
                    .foregroundColor(Color(hex: "c084fc"))
                    .font(.subheadline)
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    Text("30s preview")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                }
            }
            .padding(24)
            .frame(width: 320, alignment: .leading)

            // Swipe overlays
            if offset.width > 50 {
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color(hex: "a855f7"), lineWidth: 4)
                    .overlay(Text("LIKE")
                        .font(.system(size: 36, weight: .black))
                        .foregroundColor(Color(hex: "a855f7"))
                        .rotationEffect(.degrees(-15)))
                    .frame(width: 320, height: 460)
                    .opacity(Double(min(offset.width / 100, 1)))
            } else if offset.width < -50 {
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.red, lineWidth: 4)
                    .overlay(Text("NOPE")
                        .font(.system(size: 36, weight: .black))
                        .foregroundColor(.red)
                        .rotationEffect(.degrees(15)))
                    .frame(width: 320, height: 460)
                    .opacity(Double(min(-offset.width / 100, 1)))
            }
        }
    }

    var artPlaceholder: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(LinearGradient(
                colors: [Color(hex: "2d1060"), Color(hex: "0d0620")],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 320, height: 460)
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: 60, weight: .ultraLight))
                    .foregroundColor(Color(hex: "a855f7").opacity(0.4))
            )
    }

    func circleButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.12))
                .clipShape(Circle())
                .overlay(Circle().stroke(color.opacity(0.25), lineWidth: 1))
        }
    }

    // MARK: - Swipe logic

    func handleSwipe(_ translation: CGSize) {
        if translation.width > 100 { animateSwipe(direction: "like") }
        else if translation.width < -100 { animateSwipe(direction: "dislike") }
        else { withAnimation(.spring()) { offset = .zero } }
    }

    func animateSwipe(direction: String) {
        guard let track = currentTrack else { return }
        withAnimation(.easeOut(duration: 0.3)) {
            offset = CGSize(width: direction == "like" ? 600 : -600, height: 0)
        }
        player?.pause()
        player = nil
        isPlaying = false
        Task { try? await APIService.shared.swipe(trackId: track.id, direction: direction) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            currentIndex += 1
            offset = .zero
        }
    }

    // MARK: - Playback

    func startPlayback() {
        guard let track = currentTrack, let url = URL(string: track.preview_url) else { return }
        player?.pause()
        player = AVPlayer(url: url)
        player?.play()
        isPlaying = true
    }

    func togglePlay() {
        guard let track = currentTrack else { return }
        if let p = player {
            if p.timeControlStatus == .playing { p.pause(); isPlaying = false }
            else { p.play(); isPlaying = true }
        } else {
            player = AVPlayer(url: URL(string: track.preview_url)!)
            player?.play()
            isPlaying = true
        }
    }

    func loadTracks() {
        loading = true
        errorMessage = nil
        currentIndex = 0
        player?.pause(); player = nil; isPlaying = false
        Task {
            do {
                let results = try await APIService.shared.recommendations(searchTerm: searchTerm)
                await MainActor.run {
                    if results.isEmpty {
                        errorMessage = "No songs found. Try a different search."
                    } else {
                        tracks = results
                        if autoplay { startPlayback() }
                    }
                    loading = false
                }
            } catch APIError.server(let code) {
                await MainActor.run {
                    errorMessage = "Server error (\(code)). Tap Try Again."
                    loading = false
                }
            } catch APIError.unauthorized {
                await MainActor.run { loading = false }
            } catch {
                await MainActor.run {
                    errorMessage = "Couldn't reach the server. Check your connection and try again."
                    loading = false
                }
            }
        }
    }
}
