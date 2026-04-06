import SwiftUI

struct RecommendationsView: View {
    @State private var tracks: [Track] = []
    @State private var loading = false
    @State private var search = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("For You")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 16)

                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray)
                    TextField("Search artist or genre", text: $search)
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .onSubmit { fetchRecs() }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .padding()

                if loading {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(tracks) { track in
                                TrackRow(track: track)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .onAppear { fetchRecs() }
    }

    func fetchRecs() {
        let term = search.isEmpty ? "top hits" : search
        loading = true
        Task {
            let results = (try? await APIService.shared.recommendations(searchTerm: term)) ?? []
            await MainActor.run {
                tracks = results
                loading = false
            }
        }
    }
}

struct TrackRow: View {
    let track: Track

    var body: some View {
        HStack(spacing: 14) {
            // Artwork
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "2a1040"))
                    .frame(width: 52, height: 52)
                if let urlStr = track.artwork_url, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        if let img = phase.image {
                            img.resizable().aspectRatio(contentMode: .fill)
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Image(systemName: "music.note")
                                .foregroundColor(Color(hex: "a855f7"))
                        }
                    }
                } else {
                    Image(systemName: "music.note")
                        .foregroundColor(Color(hex: "a855f7"))
                }
            }
            .frame(width: 52, height: 52)

            // Title + artist
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(track.artist)
                    .foregroundColor(.gray)
                    .font(.caption)
                    .lineLimit(1)
            }

            Spacer()

            // Score
            if let score = track.score {
                Text("\(Int(score * 100))%")
                    .font(.caption)
                    .foregroundColor(Color(hex: "a855f7"))
                    .frame(minWidth: 32)
            }

            // Open in Spotify
            Button(action: { openSpotify(track: track) }) {
                Image("spotify_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            // Open in Apple Music
            Button(action: { openAppleMusic(track: track) }) {
                Image("applemusic_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(14)
    }

    func openSpotify(track: Track) {
        let query = "\(track.title) \(track.artist)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        // Try Spotify app deep link first, fall back to web
        if let appURL = URL(string: "spotify:search:\(query)"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let webURL = URL(string: "https://open.spotify.com/search/\(query)") {
            UIApplication.shared.open(webURL)
        }
    }

    func openAppleMusic(track: Track) {
        let query = "\(track.title) \(track.artist)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let appURL = URL(string: "music://music.apple.com/search?term=\(query)"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let webURL = URL(string: "https://music.apple.com/search?term=\(query)") {
            UIApplication.shared.open(webURL)
        }
    }
}
