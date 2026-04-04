import SwiftUI

struct ProfileView: View {
    @AppStorage("auth_token") var token = ""
    @AppStorage("user_id") var userId = 0
    @AppStorage("onboarding_done") var onboardingDone = false
    @AppStorage("username") var storedUsername = ""

    @State private var likedTracks: [FriendTasteTrack] = []
    @State private var friendCount = 0
    @State private var postCount = 0
    @State private var loading = true
    @State private var showLogoutConfirm = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "7c3aed"), Color(hex: "a855f7")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 80)
                            Text(storedUsername.prefix(1).uppercased())
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 32)

                        Text(storedUsername)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        Text("@\(storedUsername)")
                            .font(.caption)
                            .foregroundColor(Color(hex: "b084f5"))

                        HStack(spacing: 12) {
                            statPill(value: "\(likedTracks.count)", label: "Liked")
                            statPill(value: "\(friendCount)", label: "Friends")
                            statPill(value: "\(postCount)", label: "Posts")
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 28)

                    // Liked songs
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOUR TASTE")
                            .foregroundColor(.gray)
                            .font(.caption.bold())
                            .padding(.horizontal)

                        if loading {
                            HStack {
                                Spacer()
                                ProgressView().tint(.white).padding(32)
                                Spacer()
                            }
                        } else if likedTracks.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "heart.slash")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color(hex: "a855f7").opacity(0.5))
                                Text("No likes yet — start swiping!")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(32)
                        } else {
                            ForEach(likedTracks) { track in
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(hex: "2a1040"))
                                        Image(systemName: "music.note")
                                            .foregroundColor(Color(hex: "a855f7"))
                                            .font(.system(size: 14))
                                    }
                                    .frame(width: 42, height: 42)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(track.title)
                                            .foregroundColor(.white)
                                            .fontWeight(.semibold)
                                            .lineLimit(1)
                                        Text(track.artist)
                                            .foregroundColor(Color(hex: "b084f5"))
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Logout
                    Button(action: { showLogoutConfirm = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log Out")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.red.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 48)
                }
            }
        }
        .confirmationDialog("Log out?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) {
                token = ""
                onboardingDone = false
                storedUsername = ""
                userId = 0
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear { loadLikes() }
    }

    func statPill(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }

    func loadLikes() {
        loading = true
        Task {
            async let likes = APIService.shared.getMyLikes()
            async let friends = APIService.shared.getFriends()
            async let posts = APIService.shared.getMyPostCount()
            likedTracks = (try? await likes) ?? []
            friendCount = (try? await friends)?.count ?? 0
            postCount = (try? await posts) ?? 0
            await MainActor.run { loading = false }
        }
    }
}
