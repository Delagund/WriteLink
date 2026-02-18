/// Use Case para editar una nota existente.
///
/// **Patrón Command:**
/// - Operación "editar nota" encapsulada y ejecutable
/// - Mantiene historial de cambios (futuro: Memento pattern)
///
/// **Reglas de negocio:**
/// - Solo actualiza `updatedAt` si el contenido realmente cambió
/// - Valida que la nota exista antes de actualizar
/// - Preserva `createdAt` (inmutable)


import Foundation

actor EditNoteUseCase {
    private let repository: NoteRepositoryProtocol
    private let now: @Sendable () -> Date   // Guardamos la propiedad de forma que sea una funcion que cree la fecha cuando la necesitamos
    
    init(repository: NoteRepositoryProtocol,
         now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.now = now
    }
    
    // MARK: - Execution
    
    /// Actualiza el contenido de una nota existente
    ///
    /// - Parameters:
    ///   - id: UUID de la nota a editar
    ///   - newContent: Nuevo contenido
    /// - Returns: La nota actualizada
    /// - Throws:
    ///   - `UseCaseError.notFound` si la nota no existe
    ///   - `RepositoryError` si falla la persistencia
    func execute(id: UUID, newContent: String) async throws -> Note {
        
        // 1. Obtener la nota actual
        guard let currentNote = try await repository.getNoteById(id) else {
            throw UseCaseError.notFound(id)
        }
        
        // 2. Verificar si realmente cambió (optimización)
        guard currentNote.content != newContent else {
            return currentNote
        }
        
        // 3. Actualizamos el contenido de la nota y agregamos la fecha del cambio
        let updatedNote = currentNote.updatingContent(newContent, at: now())
        
        // 4. Persistimos la nota actualizada al repositorio
        return try await repository.update(updatedNote)
    }
    
    /// Actualiza el título de una nota
    func execute(id:UUID, newTitle: String) async throws -> Note {
        // 1. Obtener la nota actual
        guard let currentNote = try await repository.getNoteById(id) else {
            throw UseCaseError.notFound(id)
        }
        
        // 2. Verifica que el titulo no esté vacio
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw UseCaseError.invalidInput("El título no puede estar vacío")
        }
        
        // 3. Verificar cambio de titulo
        guard currentNote.title != trimmedTitle else {
            return currentNote
        }
        
        // 4. Actualiza titulo de la nota y agrega fecha del cambio
        let updatedNote = currentNote.updatingTitle(trimmedTitle, at: now())
        
        // 5. Persistencia de nota actualizada al repositorio
        return try await repository.update(updatedNote)
    }
    
    /// Actualiza título y contenido simultáneamente
    func execute(id:UUID, newTitle: String, newContent: String) async throws -> Note {
        // 1. Obtener la nota actual
        guard let currentNote = try await repository.getNoteById(id) else {
            throw UseCaseError.notFound(id)
        }
        
        // 2. Verifica que el titulo no esté vacio
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw UseCaseError.invalidInput("El título no puede estar vacío")
        }
        
        // 3. Verificar cambios
        guard currentNote.title != trimmedTitle || currentNote.content != newContent else {
            return currentNote
        }
        
        // 4. Actualiza la nota y agrega fecha del cambio
        let updatedNote = currentNote.updating(title: trimmedTitle, content: newContent, at: now())
        
        // 5. Persistencia de la nota actualizada
        return try await repository.update(updatedNote)
    }
    
    // Actualiza una nota completa (útil para sincronización)
    func execute(note: Note) async throws -> Note {
        // Verificar que la nota existe
        guard try await repository.getNoteById(note.id) != nil else {
            throw UseCaseError.notFound(note.id)
        }
        
        return try await repository.update(note)
    }
}
