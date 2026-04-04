import SwiftUI

struct CommunityView: View {
    @AppStorage("username") var storedUsername = ""

    @State private var selectedTab = 0  // 0 = Feed, 1 = Friends
    @State private var posts: [Post] = []
    @State private var selectedCategory: String? = nil
    @State private var showCreatePost = false
    @State private var friends: [Friend] = []
    @State private var requests: [FriendRequest] = []
    @State private var addUsername = ""
    @State private var showAddSheet = false
    @State private var addStatus: String? = nil
    @State private var selectedFriend: Friend?
    @State private var friendTracks: [FriendTasteTrack] = []
    @State private var showTasteSheet = false
    @State private var loadingPosts = true

    let categories = ["General", "Discovery", "Recommendations", "Music Talk", "Question"]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Community")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if selectedTab == 0 {
                        Button(action: { showCreatePost = true }) {
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(Color(hex: "a855f7"))
                                .font(.system(size: 20))
                        }
                    } else {
                        Button(action: { showAddSheet = true }) {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)

                // Segment
                HStack(spacing: 0) {
                    segmentButton("Feed", index: 0)
                    segmentButton("Friends", index: 1)
                }
                .padding(.horizontal)
                .padding(.bottom, 12)

                if selectedTab == 0 {
                    feedView
                } else {
                    friendsView
                }
            }
        }
        .sheet(isPresented: $showCreatePost) { createPostSheet }
        .sheet(isPresented: $showAddSheet) { addFriendSheet }
        .sheet(isPresented: $showTasteSheet) { tasteSheet }
        .onAppear { loadAll() }
    }

    func segmentButton(_ label: String, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            Text(label)
                .fontWeight(.semibold)
                .font(.subheadline)
                .foregroundColor(selectedTab == index ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    selectedTab == index
                        ? Color(hex: "7c3aed").opacity(0.6)
                        : Color.clear
                )
                .cornerRadius(10)
        }
    }

    // MARK: - Feed

    var feedView: some View {
        VStack(spacing: 0) {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryChip("All", selected: selectedCategory == nil) {
                        selectedCategory = nil
                        loadPosts()
                    }
                    ForEach(categories, id: \.self) { cat in
                        categoryChip(cat, selected: selectedCategory == cat) {
                            selectedCategory = cat
                            loadPosts()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }

            if loadingPosts {
                Spacer()
                ProgressView().tint(.white)
                Spacer()
            } else if posts.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: "a855f7").opacity(0.5))
                    Text("No posts yet — be the first!")
                        .foregroundColor(.gray)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(posts) { post in
                            postRow(post)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
    }

    func categoryChip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .foregroundColor(selected ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected ? Color(hex: "7c3aed") : Color.white.opacity(0.07))
                .cornerRadius(20)
        }
    }

    func postRow(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: "2a1040"))
                        .frame(width: 34, height: 34)
                    Text(post.username.prefix(1).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "a855f7"))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("@\(post.username)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                    Text(timeAgo(post.created_at))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Spacer()
                Text(post.category)
                    .font(.caption2.bold())
                    .foregroundColor(Color(hex: "a855f7"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "a855f7").opacity(0.15))
                    .cornerRadius(8)
            }
            Text(post.content)
                .foregroundColor(.white)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(14)
    }

    func timeAgo(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) else { return "" }
        let diff = Int(Date().timeIntervalSince(date))
        if diff < 60 { return "just now" }
        if diff < 3600 { return "\(diff / 60)m ago" }
        if diff < 86400 { return "\(diff / 3600)h ago" }
        return "\(diff / 86400)d ago"
    }

    // MARK: - Friends

    var friendsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !requests.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("REQUESTS")
                            .foregroundColor(.gray)
                            .font(.caption.bold())
                            .padding(.horizontal)
                        ForEach(requests) { req in requestRow(req) }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("FRIENDS")
                        .foregroundColor(.gray)
                        .font(.caption.bold())
                        .padding(.horizontal)
                    if friends.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.2")
                                .font(.system(size: 36))
                                .foregroundColor(Color(hex: "a855f7").opacity(0.5))
                            Text("No friends yet")
                                .foregroundColor(.gray)
                            Button("Add someone") { showAddSheet = true }
                                .foregroundColor(Color(hex: "a855f7"))
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                    } else {
                        ForEach(friends) { friend in friendRow(friend) }
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }

    func requestRow(_ req: FriendRequest) -> some View {
        HStack {
            ZStack {
                Circle().fill(Color(hex: "2a1040")).frame(width: 40, height: 40)
                Text(req.username.prefix(1).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "a855f7"))
            }
            VStack(alignment: .leading) {
                Text(req.username).foregroundColor(.white).fontWeight(.semibold)
                Text("wants to connect").foregroundColor(.gray).font(.caption)
            }
            Spacer()
            Button("Accept") {
                Task {
                    try? await APIService.shared.acceptFriend(friendshipId: req.friendship_id)
                    loadFriends()
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(LinearGradient(colors: [Color(hex: "7c3aed"), Color(hex: "a855f7")],
                                       startPoint: .leading, endPoint: .trailing))
            .cornerRadius(10)
            .foregroundColor(.white)
            .font(.caption.bold())
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(14)
        .padding(.horizontal)
    }

    func friendRow(_ friend: Friend) -> some View {
        HStack {
            ZStack {
                Circle().fill(Color(hex: "2a1040")).frame(width: 40, height: 40)
                Text(friend.username.prefix(1).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.gray)
            }
            Text(friend.username).foregroundColor(.white).fontWeight(.semibold)
            Spacer()
            Button("See Taste") {
                selectedFriend = friend
                Task {
                    friendTracks = (try? await APIService.shared.friendTaste(friendId: friend.user_id)) ?? []
                    await MainActor.run { showTasteSheet = true }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Color.white.opacity(0.08))
            .cornerRadius(10)
            .foregroundColor(.white)
            .font(.caption.bold())
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(14)
        .padding(.horizontal)
    }

    // MARK: - Sheets

    var createPostSheet: some View {
        CreatePostView(onPost: {
            showCreatePost = false
            loadPosts()
        })
    }

    var addFriendSheet: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button("Cancel") { showAddSheet = false }
                        .foregroundColor(.gray).padding()
                }
                Spacer()
                Text("Add Friend")
                    .font(.title2.bold()).foregroundColor(.white)
                TextField("Enter their username", text: $addUsername)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "a855f7").opacity(0.3), lineWidth: 1))
                    .padding(.horizontal, 32)
                if let status = addStatus {
                    Text(status)
                        .foregroundColor(status.contains("sent") ? Color(hex: "a855f7") : .red)
                        .font(.caption)
                }
                Button("Send Request") {
                    guard !addUsername.isEmpty else { return }
                    Task {
                        do {
                            try await APIService.shared.addFriend(username: addUsername)
                            await MainActor.run { addStatus = "Request sent to @\(addUsername)!"; addUsername = "" }
                        } catch {
                            await MainActor.run { addStatus = "User not found or request already sent." }
                        }
                    }
                }
                .frame(maxWidth: .infinity).padding()
                .background(LinearGradient(colors: [Color(hex: "7c3aed"), Color(hex: "a855f7")],
                                           startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white).fontWeight(.bold)
                .cornerRadius(12).padding(.horizontal, 32)
                .disabled(addUsername.isEmpty)
                Spacer()
            }
        }
    }

    var tasteSheet: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    Button("Done") { showTasteSheet = false }
                        .foregroundColor(.gray).padding()
                }
                Text("\(selectedFriend?.username ?? "")'s Taste")
                    .font(.title2.bold()).foregroundColor(.white)
                if friendTracks.isEmpty {
                    Text("Nothing liked yet.").foregroundColor(.gray).padding()
                } else {
                    ScrollView {
                        ForEach(friendTracks) { track in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(track.title).foregroundColor(.white).fontWeight(.semibold)
                                    Text(track.artist).foregroundColor(.gray).font(.caption)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Data

    func loadAll() {
        loadPosts()
        loadFriends()
    }

    func loadPosts() {
        loadingPosts = true
        Task {
            posts = (try? await APIService.shared.getPosts(category: selectedCategory)) ?? []
            await MainActor.run { loadingPosts = false }
        }
    }

    func loadFriends() {
        Task {
            async let f = APIService.shared.getFriends()
            async let r = APIService.shared.getFriendRequests()
            let (fr, rq) = (try? await (f, r)) ?? ([], [])
            await MainActor.run { friends = fr; requests = rq }
        }
    }
}

// MARK: - Create Post Sheet

struct CreatePostView: View {
    let onPost: () -> Void
    @State private var content = ""
    @State private var selectedCategory = "General"
    @State private var posting = false
    @State private var error = ""
    @Environment(\.dismiss) var dismiss

    let categories = ["General", "Discovery", "Recommendations", "Music Talk", "Question"]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.gray)
                    Spacer()
                    Text("New Post")
                        .font(.headline).foregroundColor(.white)
                    Spacer()
                    Button("Post") { submitPost() }
                        .fontWeight(.bold)
                        .foregroundColor(content.isEmpty ? .gray : Color(hex: "a855f7"))
                        .disabled(content.isEmpty || posting)
                }
                .padding()

                // Category picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            Button(action: { selectedCategory = cat }) {
                                Text(cat)
                                    .font(.caption.bold())
                                    .foregroundColor(selectedCategory == cat ? .white : .gray)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategory == cat ? Color(hex: "7c3aed") : Color.white.opacity(0.07))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                ZStack(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("What's on your mind? Share a discovery, ask for recs...")
                            .foregroundColor(.gray.opacity(0.6))
                            .font(.subheadline)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                    }
                    TextEditor(text: $content)
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 120, maxHeight: 200)
                        .onChange(of: content) { _, v in if v.count > 280 { content = String(v.prefix(280)) } }
                }
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.06))
                .cornerRadius(14)
                .padding(.horizontal)

                HStack {
                    Spacer()
                    Text("\(content.count)/280")
                        .font(.caption2)
                        .foregroundColor(content.count > 250 ? .orange : .gray)
                        .padding(.trailing)
                }

                if !error.isEmpty {
                    Text(error).foregroundColor(.red).font(.caption)
                }

                Spacer()
            }
        }
    }

    func submitPost() {
        posting = true
        Task {
            do {
                try await APIService.shared.createPost(content: content, category: selectedCategory)
                await MainActor.run { onPost() }
            } catch {
                await MainActor.run {
                    self.error = "Couldn't post. Try again."
                    posting = false
                }
            }
        }
    }
}
