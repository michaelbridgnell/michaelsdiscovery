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
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.purple.opacity(0.3))
                    .frame(width: 52, height: 52)
                Image(systemName: "music.note")
                    .foregroundColor(.purple)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(track.artist)
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            Spacer()
            if let score = track.score {
                Text("\(Int(score * 100))%")
                    .font(.caption)
                    .foregroundColor(.purple)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(14)
    }
}
