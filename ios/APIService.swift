import Foundation

enum APIError: Error {
    case unauthorized
    case server(Int)
}

class APIService {
    static let shared = APIService()
    private let base = "https://michaelsdiscovery.onrender.com"

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 120
        return URLSession(configuration: config)
    }()

    // 300s for CLAP-heavy endpoints (model load + audio downloads on cold start)
    private let slowSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config)
    }()

    private var token: String? {
        UserDefaults.standard.string(forKey: "auth_token")
    }

    private func authedRequest(_ path: String, method: String = "GET") -> URLRequest {
        var req = URLRequest(url: URL(string: base + path)!)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let t = token { req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
        return req
    }

    /// On 401, clears the stored token — @AppStorage observes this and
    /// ContentView automatically shows the login screen.
    private func checked(_ data: Data, _ response: URLResponse) throws -> Data {
        guard let http = response as? HTTPURLResponse else { return data }
        if http.statusCode == 401 {
            UserDefaults.standard.removeObject(forKey: "auth_token")
            throw APIError.unauthorized
        }
        if http.statusCode >= 400 { throw APIError.server(http.statusCode) }
        return data
    }

    func register(username: String, email: String, password: String) async throws -> AuthResponse {
        var req = authedRequest("/register", method: "POST")
        req.httpBody = try JSONEncoder().encode(["username": username, "email": email, "password": password])
        let (data, res) = try await session.data(for: req)
        return try JSONDecoder().decode(AuthResponse.self, from: checked(data, res))
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        var req = authedRequest("/login", method: "POST")
        req.httpBody = try JSONEncoder().encode(["email": email, "password": password])
        let (data, res) = try await session.data(for: req)
        return try JSONDecoder().decode(AuthResponse.self, from: checked(data, res))
    }

    func seed(titles: [String]) async throws {
        var req = authedRequest("/seed", method: "POST")
        req.httpBody = try JSONEncoder().encode(["titles": titles])
        let (data, res) = try await slowSession.data(for: req)
        _ = try checked(data, res)
    }

    func recommendations(searchTerm: String) async throws -> [Track] {
        let req = authedRequest("/recommendations/\(searchTerm.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? searchTerm)")
        let (data, res) = try await slowSession.data(for: req)
        return try JSONDecoder().decode([Track].self, from: checked(data, res))
    }

    func swipe(trackId: Int, direction: String) async throws {
        var req = authedRequest("/swipe/\(trackId)", method: "POST")
        req.httpBody = try JSONEncoder().encode(["direction": direction])
        let (data, res) = try await session.data(for: req)
        _ = try checked(data, res)
    }

    func getPosts(category: String? = nil) async throws -> [Post] {
        var path = "/posts"
        if let cat = category { path += "?category=\(cat.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cat)" }
        let req = authedRequest(path)
        let (data, res) = try await session.data(for: req)
        return try JSONDecoder().decode([Post].self, from: checked(data, res))
    }

    func createPost(content: String, category: String) async throws {
        var req = authedRequest("/posts", method: "POST")
        req.httpBody = try JSONEncoder().encode(["content": content, "category": category])
        let (data, res) = try await session.data(for: req)
        _ = try checked(data, res)
    }

    func getFriends() async throws -> [Friend] {
        let req = authedRequest("/friends")
        let (data, res) = try await session.data(for: req)
        return try JSONDecoder().decode([Friend].self, from: checked(data, res))
    }

    func getFriendRequests() async throws -> [FriendRequest] {
        let req = authedRequest("/friends/requests")
        let (data, res) = try await session.data(for: req)
        return try JSONDecoder().decode([FriendRequest].self, from: checked(data, res))
    }

    func addFriend(username: String) async throws {
        var req = authedRequest("/friends/add", method: "POST")
        req.httpBody = try JSONEncoder().encode(["username": username])
        let (data, res) = try await session.data(for: req)
        _ = try checked(data, res)
    }

    func acceptFriend(friendshipId: Int) async throws {
        var req = authedRequest("/friends/accept/\(friendshipId)", method: "POST")
        req.httpMethod = "POST"
        let (data, res) = try await session.data(for: req)
        _ = try checked(data, res)
    }

    func friendTaste(friendId: Int) async throws -> [FriendTasteTrack] {
        let req = authedRequest("/friends/\(friendId)/taste")
        let (data, res) = try await session.data(for: req)
        return try JSONDecoder().decode([FriendTasteTrack].self, from: checked(data, res))
    }

    func getMyLikes() async throws -> [FriendTasteTrack] {
        let req = authedRequest("/me/likes")
        let (data, res) = try await session.data(for: req)
        return try JSONDecoder().decode([FriendTasteTrack].self, from: checked(data, res))
    }

    func getMyPostCount() async throws -> Int {
        let req = authedRequest("/me/posts/count")
        let (data, res) = try await session.data(for: req)
        return try JSONDecoder().decode(PostCountResponse.self, from: checked(data, res)).count
    }
}
