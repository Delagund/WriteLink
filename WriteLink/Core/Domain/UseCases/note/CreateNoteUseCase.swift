/// Use Case para crear una nueva nota en el sistema.
///
/// **Patrón Command:**
/// - Encapsula la operación "crear nota" como un objeto ejecutable
/// - Facilita Undo/Redo en fases futuras (Memento pattern)
/// - Separación de concerns: lógica de negocio vs persistencia
///
/// **Responsabilidades:**
/// 1. Validar entrada del usuario
/// 2. Aplicar reglas de negocio (ej: título único, contenido mínimo)
/// 3. Delegar persistencia al Repository
/// 4. Retornar resultado o error
///
/// **Ejemplo de uso:**
/// ```swift
/// let useCase = CreateNoteUseCase(repository: noteRepository)
/// let note = try await useCase.execute(title: "Mi Nota", content: "Contenido")
/// ``
/// - Note: `actor` aislamiento protege contra race conditions
import Foundation

actor CreateNoteUseCase {
    private let repository: NoteRepositoryProtocol
    
    init(repository: NoteRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(title: String, content: String = "", createdAt: Date = Date()) async throws -> Note {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw UseCaseError.invalidInput("El título no puede estar vacío")
        }
        
        let newNote =  Note(
            id: UUID(),
            title: trimmedTitle,
            content: content,
            createdAt: createdAt,
            updatedAt: Date()
        )
        return try await repository.create(newNote)
    }
}
