import Foundation

struct AuthResponse: Codable {
    let user_id: Int
    let token: String
    let username: String
}

struct Track: Codable, Identifiable {
    let id: Int
    let title: String
    let artist: String
    let preview_url: String
    var score: Double?
}

struct Friend: Codable, Identifiable {
    let user_id: Int
    let username: String
    var id: Int { user_id }
}

struct FriendRequest: Codable, Identifiable {
    let friendship_id: Int
    let from_user_id: Int
    let username: String
    var id: Int { friendship_id }
}

struct FriendTasteTrack: Codable, Identifiable {
    let title: String
    let artist: String
    var id: String { "\(title)\(artist)" }
}

struct Post: Codable, Identifiable {
    let id: Int
    let user_id: Int
    let username: String
    let content: String
    let category: String
    let created_at: String
}

struct PostCountResponse: Codable {
    let count: Int
}
