import Foundation

struct Chapter: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var url: String
    var content: String?
}