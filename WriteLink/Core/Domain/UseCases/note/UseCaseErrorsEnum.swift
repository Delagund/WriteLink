import Foundation

// MARK: - Repository Errors

/// Errores específicos de operaciones de repositorio
enum UseCaseError: Error, LocalizedError {
    case notFound(UUID)
    case alreadyExists(UUID)
    case invalidInput(String)
    

    var errorDescription: String? {
        switch self {
        case .notFound(let id):
            return "Nota no encontrada: \(id.uuidString)"
        case .alreadyExists(let id):
            return "La nota ya existe: \(id.uuidString)"
        case .invalidInput(let reason):
            return "\(reason)"
        }
    }
}
