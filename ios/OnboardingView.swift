import SwiftUI

struct iTunesSuggestion: Identifiable {
    let id = UUID()
    let track: String
    let artist: String
    let artworkUrl: String?
}

struct SongSeedRow: View {
    let index: Int
    @Binding var value: String
    @Binding var focusedIndex: Int?

    @State private var suggestions: [iTunesSuggestion] = []
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var fieldFocused: Bool

    var isFocused: Bool { focusedIndex == index }

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(isFocused ? Color(hex: "a855f7") : Color.white.opacity(0.3))
                    .frame(width: 18)

                TextField("Search song or artist", text: $value)
                    .font(.system(size: 15, weight: .medium))
                    .autocapitalization(.none)
                    .foregroundColor(.white)
                    .focused($fieldFocused)
                    .onChange(of: fieldFocused) { _, focused in
                        if focused {
                            focusedIndex = index
                            if suggestions.isEmpty { loadDefault() }
                        }
                    }
                    .onChange(of: value) { _, newVal in
                        searchTask?.cancel()
                        searchTask = Task {
                            try? await Task.sleep(nanoseconds: 150_000_000)
                            guard !Task.isCancelled else { return }
                            let results = await searchITunes(newVal)
                            await MainActor.run { suggestions = results }
                        }
                    }

                if !value.isEmpty {
                    Button(action: {
                        value = ""
                        suggestions = []
                        loadDefault()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.white.opacity(0.25))
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(isFocused ? 0.1 : 0.06)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "a855f7").opacity(isFocused ? 0.5 : 0.1), lineWidth: 1))
            .animation(.easeInOut(duration: 0.15), value: isFocused)

            if isFocused && !suggestions.isEmpty {
                ZStack(alignment: .bottom) {
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(suggestions) { suggestion in
                                Button(action: {
                                    value = "\(suggestion.track) - \(suggestion.artist)"
                                    suggestions = []
                                    focusedIndex = nil
                                }) {
                                    HStack(spacing: 12) {
                                        AsyncImage(url: suggestion.artworkUrl.flatMap { URL(string: $0) }) { phase in
                                            if let img = phase.image {
                                                img.resizable().aspectRatio(contentMode: .fill)
                                            } else {
                                                ZStack {
                                                    Color(hex: "2a1040")
                                                    Image(systemName: "music.note")
                                                        .foregroundColor(Color(hex: "a855f7"))
                                                        .font(.system(size: 13))
                                                }
                                            }
                                        }
                                        .frame(width: 42, height: 42)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(suggestion.track)
                                                .foregroundColor(.white)
                                                .font(.system(size: 14, weight: .semibold))
                                                .lineLimit(1)
                                            Text(suggestion.artist)
                                                .foregroundColor(Color(hex: "b084f5"))
                                                .font(.system(size: 12))
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .frame(maxHeight: 160)

                    LinearGradient(
                        colors: [Color.clear, Color(hex: "0e0618")],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 36)
                    .allowsHitTesting(false)
                }
                .background(Color(hex: "0e0618"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "a855f7").opacity(0.3), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.7), radius: 20, x: 0, y: 8)
                .offset(y: 48)
                .zIndex(10)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.15), value: isFocused)
            }
        }
    }

    func loadDefault() {
        searchTask?.cancel()
        searchTask = Task {
            let results = await searchITunes("")
            await MainActor.run { suggestions = results }
        }
    }

    func searchITunes(_ query: String) async -> [iTunesSuggestion] {
        let term = query.isEmpty ? "top hits 2024" : query
        guard let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?term=\(encoded)&media=music&limit=6")
        else { return [] }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]]
        else { return [] }
        return results.compactMap { item in
            guard let track = item["trackName"] as? String,
                  let artist = item["artistName"] as? String else { return nil }
            let art = (item["artworkUrl100"] as? String)?.replacingOccurrences(of: "100x100", with: "300x300")
            return iTunesSuggestion(track: track, artist: artist, artworkUrl: art)
        }
    }
}

struct OnboardingView: View {
    @AppStorage("onboarding_done") var onboardingDone = false
    @State private var songs = ["", "", ""]
    @State private var focusedIndex: Int? = nil
    @State private var loading = false
    @State private var error = ""
    @State private var appeared = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "1a0533"), Color.black],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            GeometryReader { geo in
                Ellipse()
                    .fill(LinearGradient(
                        colors: [Color(hex: "7c3aed").opacity(0.65), Color(hex: "ec4899").opacity(0.35)],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * 1.3, height: 130)
                    .rotationEffect(.degrees(-10))
                    .offset(x: -geo.size.width * 0.15, y: geo.size.height * 0.2)
                    .blur(radius: 44)
            }
            .ignoresSafeArea()

            if focusedIndex != nil {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture { focusedIndex = nil }
            }

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 10) {
                    Text("Your taste,\nyour music.")
                        .font(.system(size: 38, weight: .black))
                        .foregroundStyle(LinearGradient(
                            colors: [.white, Color(hex: "c084fc")],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .multilineTextAlignment(.center)

                    Text("Add 3 songs you love to train your model.")
                        .foregroundColor(Color(hex: "9d7fc4"))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { i in
                        SongSeedRow(index: i, value: $songs[i], focusedIndex: $focusedIndex)
                            .zIndex(Double(3 - i))
                    }
                }
                .padding(.horizontal, 24)

                if !error.isEmpty {
                    Text(error).foregroundColor(.red).font(.caption)
                }

                VStack(spacing: 12) {
                    Button(action: seedAndContinue) {
                        if loading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Build My Taste")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(
                        colors: [Color(hex: "7c3aed"), Color(hex: "a855f7")],
                        startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(14)
                    .padding(.horizontal, 24)
                    .disabled(loading)

                    Button("Skip — discover from scratch") {
                        onboardingDone = true
                    }
                    .foregroundColor(Color(hex: "9d7fc4"))
                    .font(.footnote)
                }

                Spacer()
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) { appeared = true }
            }
        }
    }

    func seedAndContinue() {
        let filled = songs.map { $0.components(separatedBy: " - ").first ?? $0 }.filter { !$0.isEmpty }
        guard filled.count >= 3 else { error = "Please enter at least 3 songs."; return }
        loading = true
        Task {
            do {
                try await APIService.shared.seed(titles: filled)
                await MainActor.run { onboardingDone = true }
            } catch {
                await MainActor.run {
                    self.error = "Server is waking up — this can take up to 2 min on first use. Try again."
                    loading = false
                }
            }
        }
    }
}
