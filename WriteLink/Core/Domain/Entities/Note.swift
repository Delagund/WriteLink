import Foundation

struct Note: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var content: String
    let createdAt: Date
    var updatedAt: Date
    
    
    init(
        id: UUID,
        title: String,
        content: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(title: String, content: String = "") {
        let now = Date()
        self.init(
            id: UUID(),
            title: title,
            content: content,
            createdAt: now,
            updatedAt: now,
        )
    }
}
