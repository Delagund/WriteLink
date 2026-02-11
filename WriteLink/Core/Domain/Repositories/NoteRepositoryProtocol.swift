import Foundation

/// Protocolo que define las operaciones de persistencia para notas.
///
/// **Principio de Inversión de Dependencias (SOLID):**
/// - El dominio define ESTE contrato
/// - Las capas externas (Data) lo implementan
/// - Los Use Cases dependen de la abstracción, no de implementaciones concretas
///
/// **Ventajas:**
/// - Testeable: Puedes crear un `MockNoteRepository` para tests
/// - Flexible: Cambiar de FileSystem a CloudKit sin tocar Use Cases
/// - Mantenible: Contrato claro de responsabilidades

protocol NoteRepositoryProtocol: Sendable {
    // MARK: - CRUD Operations

    /// Crea una nueva nota en el sistema de persistencia
    /// - Parameter note: Nota a crear
    /// - Returns: La nota creada (con posibles metadatos adicionales del sistema)
    /// - Throws: `RepositoryError` si falla la operación
    func create(_ note: Note) async throws -> Note

    /// Obtiene una nota por su identificador
    /// - Parameter id: UUID de la nota
    /// - Returns: La nota si existe, `nil` si no se encuentra
    /// - Throws: `RepositoryError` si falla la lectura
    func getNoteById(_ id: UUID) async throws -> Note?

    /// Actualiza una nota existente
    /// - Parameter note: Nota con los datos actualizados
    /// - Returns: La nota actualizada
    /// - Throws: `RepositoryError.notFound` si la nota no existe
    func update(_ note: Note) async throws -> Note

    /// Elimina una nota por su identificador
    /// - Parameter id: UUID de la nota a eliminar
    /// - Throws: `RepositoryError.notFound` si la nota no existe
    func deleteById(_ id: UUID) async throws

    /// Obtiene todas las notas del repositorio
    /// - Returns: Array de todas las notas
    /// - Throws: `RepositoryError` si falla la lectura
    /// - Note: Para MVP, sin paginación. En producción, usar AsyncSequence
    func getAll() async throws -> [Note]

    // MARK: - Query Operations

    /// Busca notas que contengan el texto especificado
    /// - Parameter query: Texto a buscar (case-insensitive)
    /// - Returns: Array de notas que coinciden
    /// - Throws: `RepositoryError` si falla la búsqueda
    /// - Note: Para MVP, búsqueda simple. Fase 2: full-text search con índice
    func search(query: String) async throws -> [Note]

    /// Obtiene notas modificadas después de una fecha
    /// - Parameter date: Fecha de referencia
    /// - Returns: Notas modificadas después de `date`
    /// - Throws: `RepositoryError` si falla la consulta
    /// - Note: Útil para sincronización incremental en fases futuras
    func fetchModified(since date: Date) async throws -> [Note]
}


