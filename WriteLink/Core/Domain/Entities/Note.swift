/// Entidad de dominio que representa una nota en el sistema.
///
/// **Decisiones de diseño:**
/// - `struct`: Value semantics para inmutabilidad y thread-safety (Swift 6 concurrency)
/// - `Identifiable`: Integración automática con SwiftUI ForEach
/// - `Codable`: Serialización para persistencia y sincronización
/// - `Equatable`: Comparación por valor (útil para testing y SwiftUI diffing)
/// - `Sendable`: Garantiza seguridad en concurrencia (Swift 6)

import Foundation

nonisolated struct Note: Identifiable, Codable, Equatable, Sendable {
    // MARK: - Properties
    
    /// Identificador único global (UUID v4)
    /// - Inmutable: Una vez creado, nunca cambia
    /// - Distributed-friendly: No requiere servidor central
    let id: UUID
    
    /// Título de la nota (puede derivarse de la primera línea del content)
    /// - Usa `var` porque el usuario puede editar el título
    var title: String
    
    /// Contenido en formato Markdown
    /// - Aquí se almacenan [[wikilinks]], bloques de código, etc.
    var content: String
    
    /// Timestamp de creación (UTC)
    /// - Inmutable: Solo se establece una vez
    let createdAt: Date
    
    /// Timestamp de última modificación (UTC)
    /// - Se actualiza cada vez que cambia title o content
    var updatedAt: Date
    
    // MARK: - Computed Properties
    
    /// Indica si la nota está vacía (sin título ni contenido útil)
    var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Tamaño aproximado del contenido en bytes (útil para estadísticas)
    var contentSizeInBytes: Int {
        content.utf8.count
    }
    
    // MARK: - Initialization
    
    /// Inicializador completo (usado por el sistema de persistencia)
    nonisolated init(
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
    
    /// Inicializador de conveniencia para crear nuevas notas
    /// - Parameters:
    ///   - title: Título inicial
    ///   - content: Contenido inicial (vacío por defecto)
    /// - Returns: Note con UUID y timestamps generados automáticamente
    nonisolated init(title: String, content: String = "") {
        let now = Date()
        self.init(
            id: UUID(),
            title: title,
            content: content,
            createdAt: now,
            updatedAt: now,
        )
    }

    // MARK: - Factory Methods
    
    /// Crea una nota vacía con valores por defecto
    static func empty() -> Note {
        Note(title: "Nueva Nota", content: "")
    }
    
    // MARK: - Mutation Methods
    
    /// Crea una copia de la nota con contenido actualizado
    /// - Parameter newContent: Nuevo contenido
    /// - Returns: Nueva instancia con `modifiedAt` actualizado
    /// - Note: Los structs son inmutables, retornamos una copia modificada
    func updatingContent(_ newContent: String, at date: Date = Date()) -> Note {
        Note(
            id: id,
            title: title,
            content: newContent,
            createdAt: createdAt,
            updatedAt: date
        )
    }
    
    /// Crea una copia de la nota con título actualizado
    func updatingTitle(_ newTitle: String, at date: Date = Date()) -> Note {
        Note(
            id: id,
            title: newTitle,
            content: content,
            createdAt: createdAt,
            updatedAt: date
        )
    }
    
    /// Crea una copia con título y contenido actualizados
    func updating(title newTitle: String, content newContent: String, at date: Date = Date()) -> Note {
        Note(
            id: id,
            title: newTitle,
            content: newContent,
            createdAt: createdAt,
            updatedAt: date
        )
    }
}

// MARK: - Extensions
/// Preview data para SwiftUI Previews y Testing
///
extension Note {
    static var preview: Note {
        Note(
            id: UUID(),
            title: "Nota de Ejemplo",
            content: """
            # Bienvenido a WriteLink
            
            Esta es una nota de ejemplo con **Markdown**.
            
            ## Características
            - [[Enlaces internos]]
            - Listas
            - Código
            
            ```swift
            let note = Note(title: "Test")
            ```
            """,
            createdAt: Date().addingTimeInterval(-86400), // Ayer
            updatedAt: Date()
        )
    }
}
