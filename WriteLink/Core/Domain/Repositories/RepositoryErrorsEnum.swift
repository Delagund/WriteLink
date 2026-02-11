//
//  RepositoryErrorsEnum.swift
//  WriteLink
//
//  Created by Cristian on 11-02-26.
//

import Foundation

// MARK: - Repository Errors

/// Errores específicos de operaciones de repositorio
enum RepositoryError: Error, LocalizedError {
    case notFound(UUID)
    case alreadyExists(UUID)
    case invalidData(String)
    case fileSystemError(Error)
    case encodingError(Error)
    case decodingError(Error)
    case permissionDenied
    case diskFull

    var errorDescription: String? {
        switch self {
        case .notFound(let id):
            return "Nota no encontrada: \(id.uuidString)"
        case .alreadyExists(let id):
            return "La nota ya existe: \(id.uuidString)"
        case .invalidData(let reason):
            return "Datos inválidos: \(reason)"
        case .fileSystemError(let error):
            return "Error del sistema de archivos: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Error al codificar: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Error al decodificar: \(error.localizedDescription)"
        case .permissionDenied:
            return "Permiso denegado para acceder al archivo"
        case .diskFull:
            return "Disco lleno, no se puede guardar"
        }
    }
}
