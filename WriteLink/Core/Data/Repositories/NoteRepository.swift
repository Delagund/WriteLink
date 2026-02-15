//
//  NoteRepository.swift
//  WriteLink
//
//  Created by Cristian on 14-02-26.
//

import Foundation

actor NoteRepository: NoteRepositoryProtocol {
    
    // MARK: - Properties
        
    /// Directorio raíz donde se almacenan las notas
    private let baseDirectory: URL
        
    /// FileManager para operaciones de I/O
    private let fileManager: FileManager
    
    /// Serializar el Markdown
    private let markdownSerializer: MarkdownSerializer
    

    init(
        baseDirectory: URL? = nil,
        markdownSerializer: MarkdownSerializer = MarkdownSerializer()
        ) async throws {
            self.fileManager = FileManager.default
            self.markdownSerializer = markdownSerializer
        
        // Configurar directorio base
        if let customDirectory = baseDirectory {
            // Usar directorio personalizado (útil para tests)
            self.baseDirectory = customDirectory
        } else {
            // Directorio por defecto: ~/Documents/WriteLink
            guard let documentDirectory = fileManager.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first else {
                throw RepositoryError.fileSystemError(
                    NSError(
                        domain: "NoteRepository",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "No se pudo acceder al directorio de documentos"]
                    )
                )
            }
            self.baseDirectory = documentDirectory.appendingPathComponent("WriteLink")
        }
   
        // Crea el directorio si no existe
        try await createDirectoryIfNeeded()
    }
    
    // MARK: - Private Helpers
        
    /// Crea el directorio base si no existe
    func createDirectoryIfNeeded() async throws {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(
            atPath: baseDirectory.path,
            isDirectory: &isDirectory
        )
        
        if !exists {
            do {
                try fileManager.createDirectory(
                    at: baseDirectory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                throw RepositoryError.fileSystemError(error)
            }
        } else if !isDirectory.boolValue {
            throw RepositoryError.fileSystemError(
                NSError(domain: "NoteRepository",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "La ruta base existe pero no es un directorio"]
                )
            )
        }
    }
    
    /// Genera la URL completa del archivo para una nota
    ///
    /// **Ejemplo:**
    /// - Input: UUID "123e4567-e89b-12d3-a456-426614174000"
    /// - Output: ~/Documents/NotasApp/123e4567-e89b-12d3-a456-426614174000.md
    ///
    /// - Parameter id: UUID de la nota
    /// - Returns: URL completa del archivo
    private func fileURL(for id: UUID) -> URL {
        baseDirectory.appendingPathComponent("\(id.uuidString).md")
    }
    
    /// Lee una nota desde un archivo Markdown con frontmatter
    /// - Parameter url: URL del archivo .md
    /// - Returns: Instancia de Note
    /// - Throws: `RepositoryError.decodingError` si el formato es inválido
    private func readNoteFromDisk(url: URL) throws -> Note {
        do {
            let fileContent = try String(contentsOf: url, encoding: .utf8)
            return try markdownSerializer.deserialize(fileContent)
        } catch let error as MarkdownSerializerError {
            throw RepositoryError.decodingError(error)
        } catch {
            throw RepositoryError.fileSystemError(error)
        }
    }
    
    /// Escribe una nota al disco como Markdown con frontmatter
    /// - Parameters:
    ///   - note: Nota a guardar
    ///   - url: URL donde escribir
    /// - Throws: `RepositoryError.encodingError` o `.fileSystemError`
    private func writeNoteToDisk(note: Note, url: URL) throws {
        do {
            let markdown = markdownSerializer.serialize(note)
            try markdown.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw RepositoryError.fileSystemError(error)
        }
    }
    
    // MARK: - NoteRepositoryProtocol Implementation

    /// Crea una nueva nota en el disco
    ///
    /// **Flujo:**
    /// 1. Verificar que el UUID no existe (prevenir duplicados)
    /// 2. Escribir archivo .md
    /// 3. Retornar nota
    ///
    /// - Parameter note: Nota a crear
    /// - Returns: La misma nota (confirmación)
    /// - Throws:
    ///   - `RepositoryError.alreadyExists` si el archivo ya existe
    ///   - `RepositoryError.fileSystemError` si falla la escritura
    
    func create(_ note: Note) async throws -> Note {
        let url = fileURL(for: note.id)
        
        if fileManager.fileExists(atPath: url.path) {
            throw RepositoryError.alreadyExists(note.id)
        }
        
        try writeNoteToDisk(note: note, url: url)
        
        return note
    }
    
    /// Obtiene una nota por su ID
    ///
    /// - Parameter id: UUID de la nota
    /// - Returns: Note si existe, nil si no se encuentra
    /// - Throws: `RepositoryError.fileSystemError` si falla la lectura
    func getNoteById(_ id: UUID) async throws -> Note? {
        let url = fileURL(for: id)
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        
        return try readNoteFromDisk(url: url)
    }
    
    /// Actualiza una nota existente
    ///
    /// - Parameter note: Nota con datos actualizados
    /// - Returns: La nota actualizada
    /// - Throws:
    ///   - `RepositoryError.notFound` si la nota no existe
    ///   - `RepositoryError.fileSystemError` si falla la escritura
    func update(_ note: Note) async throws -> Note {
        let url = fileURL(for: note.id)
        
        // Verificar wi existe la nota
        guard fileManager.fileExists(atPath: url.path) else {
            throw RepositoryError.notFound(note.id)
        }
        
        try writeNoteToDisk(note: note, url: url)
        
        return note
    }
    
    // Elimina una nota del disco
    ///
    /// - Parameter id: UUID de la nota a eliminar
    /// - Throws:
    ///   - `RepositoryError.notFound` si la nota no existe
    ///   - `RepositoryError.fileSystemError` si falla la eliminación
    func deleteById(_ id: UUID) async throws {
        let url = fileURL(for: id)
        
        // Verificamos que exista la nota
        guard fileManager.fileExists(atPath: url.path) else {
            throw RepositoryError.notFound(id)
        }
        
        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw RepositoryError.fileSystemError(error)
        }
    }
    
    /// Obtiene todas las notas del repositorio
    ///
    /// **Flujo:**
    /// 1. Listar archivos .md en el directorio
    /// 2. Leer cada archivo
    /// 3. Ordenar por modifiedAt (más reciente primero)
    ///
    /// - Returns: Array de todas las notas
    /// - Throws: `RepositoryError.fileSystemError` si falla el listado
    func getAll() async throws -> [Note] {
        do {
            // 1. Listar archivos en el directorio
            let files = try fileManager.contentsOfDirectory(
                at: baseDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            // 2. Filtrar solo archivos .md
            let markdownFiles = files.filter { $0.pathExtension == "md" }
            
            // 3. Leer cada archivo (con manejo de errores tolerante)
            var notes: [Note] = []
            for fileURL in markdownFiles {
                do {
                    let note = try readNoteFromDisk(url: fileURL)
                    notes.append(note)
                } catch {
                    // Log error pero continuar (archivos corruptos no bloquean la app)
                    print("⚠️ Error leyendo \(fileURL.lastPathComponent): \(error)")
                }
            }
            
            // 4. Ordenar por fecha de modificación (más reciente primero)
            return notes.sorted { $0.updatedAt > $1.updatedAt }
            
        } catch {
            throw RepositoryError.fileSystemError(error)
        }
    }
    
    /// - Filtra en memoria
    ///
    /// **Fase 2:**
    /// - Índice invertido con Spotlight
    /// - Full-text search
    ///
    /// - Parameter query: Texto a buscar
    /// - Returns: Notas que coinciden
    func search(query: String) async throws -> [Note] {
        let allNotes = try await getAll()
            
        guard !query.isEmpty else {
            return allNotes
        }
        
        let lowercasedQuery = query.lowercased()
        
        return allNotes.filter { note in
            note.title.lowercased().contains(lowercasedQuery) ||
            note.content.lowercased().contains(lowercasedQuery)
        }
    }
    
    /// Obtiene notas modificadas después de una fecha
    ///
    /// - Parameter date: Fecha de referencia
    /// - Returns: Notas modificadas después de `date`
    func fetchModified(since date: Date) async throws -> [Note] {
        let allNotes = try await getAll()
        return allNotes.filter { $0.updatedAt > date }
    }
}
