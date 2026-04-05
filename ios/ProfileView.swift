import SwiftUI

struct ProfileView: View {
    @AppStorage("auth_token") var token = ""
    @AppStorage("user_id") var userId = 0
    @AppStorage("onboarding_done") var onboardingDone = false
    @AppStorage("username") var storedUsername = ""

    @State private var selectedTab = 0   // 0 = Friends, 1 = Taste
    @State private var likedTracks: [FriendTasteTrack] = []
    @State private var friends: [Friend] = []
    @State private var friendCount = 0
    @State private var postCount = 0
    @State private var loading = true
    @State private var showLogoutAlert = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {

                    // ── Avatar + name ────────────────────────────────────
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
                            statPill(value: "\(friendCount)",       label: "Friends")
                            statPill(value: "\(postCount)",         label: "Posts")
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 20)

                    // ── Segment: Friends | Taste ─────────────────────────
                    HStack(spacing: 0) {
                        segBtn("Friends", index: 0)
                        segBtn("Taste",   index: 1)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)

                    if selectedTab == 0 {
                        friendsSection
                    } else {
                        tasteSection
                    }

                    // ── Logout ───────────────────────────────────────────
                    Button(action: { showLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log Out").fontWeight(.semibold)
                        }
                        .foregroundColor(.red.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 48)
                }
            }
        }
        .alert("Log out of Sonik?", isPresented: $showLogoutAlert) {
            Button("Log Out", role: .destructive) {
                token = ""; onboardingDone = false
                storedUsername = ""; userId = 0
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear { loadAll() }
    }

    // MARK: - Segments

    func segBtn(_ label: String, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            Text(label)
                .fontWeight(.semibold).font(.subheadline)
                .foregroundColor(selectedTab == index ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedTab == index
                    ? Color(hex: "7c3aed").opacity(0.55)
                    : Color.clear)
                .cornerRadius(10)
        }
    }

    // MARK: - Friends section

    var friendsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if loading {
                HStack { Spacer(); ProgressView().tint(.white).padding(32); Spacer() }
            } else if friends.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2")
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: "a855f7").opacity(0.5))
                    Text("No friends yet")
                        .foregroundColor(.gray)
                    Text("Add friends in the Community tab")
                        .foregroundColor(.gray.opacity(0.6))
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
            } else {
                ForEach(friends) { friend in
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "2a1040"))
                                .frame(width: 44, height: 44)
                            Text(friend.username.prefix(1).uppercased())
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(hex: "a855f7"))
                        }
                        Text(friend.username)
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Taste section

    var tasteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if loading {
                HStack { Spacer(); ProgressView().tint(.white).padding(32); Spacer() }
            } else if likedTracks.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 32))
                        .foregroundColor(Color(hex: "a855f7").opacity(0.5))
                    Text("No likes yet — start swiping!")
                        .foregroundColor(.gray).font(.subheadline)
                }
                .frame(maxWidth: .infinity).padding(32)
            } else {
                ForEach(likedTracks) { track in
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8).fill(Color(hex: "2a1040"))
                            Image(systemName: "music.note")
                                .foregroundColor(Color(hex: "a855f7"))
                                .font(.system(size: 14))
                        }
                        .frame(width: 42, height: 42)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.title)
                                .foregroundColor(.white).fontWeight(.semibold).lineLimit(1)
                            Text(track.artist)
                                .foregroundColor(Color(hex: "b084f5")).font(.caption).lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Helpers

    func statPill(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 20, weight: .bold)).foregroundColor(.white)
            Text(label).font(.caption).foregroundColor(.gray)
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(Color.white.opacity(0.06)).cornerRadius(12)
    }

    func loadAll() {
        loading = true
        Task {
            async let likes   = APIService.shared.getMyLikes()
            async let fr      = APIService.shared.getFriends()
            async let posts   = APIService.shared.getMyPostCount()
            likedTracks = (try? await likes) ?? []
            friends     = (try? await fr) ?? []
            friendCount = friends.count
            postCount   = (try? await posts) ?? 0
            await MainActor.run { loading = false }
        }
    }
}
