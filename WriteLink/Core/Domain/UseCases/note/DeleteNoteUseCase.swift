/// Use Case para eliminar una nota del sistema.
///
/// **Patrón Command:**
/// - Operación reversible (futuro: papelera/trash con Memento)
/// - Validación de permisos (futuro)
///
/// **MVP:** Eliminación física inmediata
/// **Fase 2:** Papelera virtual (soft delete con flag `isDeleted`)
/// **Fase 3:** Confirmación antes de eliminar si tiene backlinks

import Foundation

actor DeleteNoteUseCase {
    private let repository: NoteRepositoryProtocol
    
    init(repository: NoteRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - Execution
    /// Elimina una nota por su ID
        ///
        /// - Parameter id: UUID de la nota a eliminar
        /// - Throws:
        ///   - `UseCaseError.notFound` si la nota no existe
        ///   - `RepositoryError` si falla la eliminación
        /// - Note: En MVP es eliminación física. Fase 2 será soft delete
    func execute(id:UUID) async throws {
        // 1. Obtener la nota actual
        guard let currentNote = try await repository.getNoteById(id) else {
            throw UseCaseError.notFound(id)
        }
        // 2. Eliminar
        // TODO: Fase 2: Verificar si tiene backlinks y advertir
        // TODO: Fase 3: Mover a papelera en vez de eliminar
        try await repository.deleteById(id)
    }
}
