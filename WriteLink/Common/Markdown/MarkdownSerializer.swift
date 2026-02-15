
import Foundation

/// Servicio para serializar/deserializar notas en formato Markdown con frontmatter YAML.
///
/// **Responsabilidad:**
/// - Convertir Note ↔ Markdown con frontmatter
/// - Parsing de YAML frontmatter
/// - Escape/unescape de caracteres especiales
///
/// **No es responsable de:**
/// - I/O de archivos (eso es del Repository)
/// - Lógica de negocio (eso es de Use Cases)
///
/// **Uso:**
/// ```swift
/// let serializer = MarkdownSerializer()
///
/// // Note → Markdown string
/// let markdown = try serializer.serialize(note)
///
/// // Markdown string → Note
/// let note = try serializer.deserialize(markdown)
/// ```
struct MarkdownSerializer: Sendable {
    
    // MARK: - Properties
    
    /// Formato de fecha ISO8601 para frontmatter
    nonisolated(unsafe) var dateFormatter: ISO8601DateFormatter
    
    // MARK: - Initialization
    
    nonisolated init() {
        self.dateFormatter = ISO8601DateFormatter()
        self.dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }
    
    // MARK: - Public API
    
    /// Serializa una Note a formato Markdown con frontmatter
    ///
    /// **Formato de salida:**
    /// ```markdown
    /// ---
    /// id: 123e4567-e89b-12d3-a456-426614174000
    /// title: Mi Nota
    /// createdAt: 2024-01-15T10:30:00.000Z
    /// modifiedAt: 2024-01-15T15:45:00.000Z
    /// ---
    ///
    /// Contenido de la nota...
    /// ```
    ///
    /// - Parameter note: Nota a serializar
    /// - Returns: String en formato Markdown con frontmatter
    nonisolated func serialize(_ note: Note) -> String {
        let frontmatter = """
        ---
        id: \(note.id.uuidString)
        title: \(escapeYAML(note.title))
        createdAt: \(dateFormatter.string(from: note.createdAt))
        modifiedAt: \(dateFormatter.string(from: note.updatedAt))
        ---
        
        """
        
        return frontmatter + note.content
    }
    
    /// Deserializa un string Markdown con frontmatter a Note
    ///
    /// - Parameter markdown: String en formato Markdown con frontmatter
    /// - Returns: Instancia de Note
    /// - Throws: `MarkdownSerializerError` si el formato es inválido
    nonisolated func deserialize(_ markdown: String) throws -> Note {
        // 1. Separar frontmatter de contenido
        let components = splitFrontmatter(from: markdown)
        
        // 2. Parsear frontmatter
        let metadata = try parseFrontmatter(components.frontmatter)
        
        // 3. Construir Note
        return Note(
            id: metadata.id,
            title: metadata.title,
            content: components.content,
            createdAt: metadata.createdAt,
            updatedAt: metadata.modifiedAt
        )
    }
    
    // MARK: - Frontmatter Parsing
    
    /// Separa el frontmatter YAML del contenido Markdown
    ///
    /// **Formato esperado:**
    /// ```
    /// ---
    /// clave: valor
    /// ---
    ///
    /// Contenido...
    /// ```
    ///
    /// - Parameter content: String completo del archivo
    /// - Returns: Tupla (frontmatter, content)
    nonisolated private func splitFrontmatter(from content: String) -> (frontmatter: String, content: String) {
        let lines = content.components(separatedBy: .newlines)
        
        // Verificar que empieza con "---"
        guard !lines.isEmpty,
              lines[0].trimmingCharacters(in: .whitespaces) == "---" else {
            // No hay frontmatter, todo es contenido
            return ("", content)
        }
        
        // Buscar el segundo "---"
        if let endIndex = lines.dropFirst().firstIndex(where: {
            $0.trimmingCharacters(in: .whitespaces) == "---"
        }) {
            let frontmatterLines = lines[1..<endIndex]
            let contentLines = lines[(endIndex + 1)...]
            
            return (
                frontmatter: frontmatterLines.joined(separator: "\n"),
                content: contentLines.joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        
        // Frontmatter malformado (no se encontró segundo "---")
        return ("", content)
    }
    
    /// Parsea frontmatter YAML a metadata estructurada
    ///
    /// **Formato esperado:**
    /// ```
    /// id: 123e4567-e89b-12d3-a456-426614174000
    /// title: Mi Nota
    /// createdAt: 2024-01-15T10:30:00.000Z
    /// modifiedAt: 2024-01-15T15:45:00.000Z
    /// ```
    ///
    /// - Parameter yaml: String con frontmatter YAML
    /// - Returns: Tupla con metadata parseada
    /// - Throws: `MarkdownSerializerError.invalidFrontmatter` si falta algún campo
    nonisolated private func parseFrontmatter(_ yaml: String) throws -> (
        id: UUID,
        title: String,
        createdAt: Date,
        modifiedAt: Date
    ) {
        var id: UUID?
        var title: String?
        var createdAt: Date?
        var modifiedAt: Date?
        
        // Parsear línea por línea (simple YAML parser)
        for line in yaml.components(separatedBy: .newlines) {
            let parts = line.split(separator: ":", maxSplits: 1)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            
            guard parts.count == 2 else { continue }
            
            let key = parts[0]
            let value = parts[1]
            
            switch key {
            case "id":
                id = UUID(uuidString: value)
            case "title":
                title = unescapeYAML(value)
            case "createdAt":
                createdAt = dateFormatter.date(from: value)
            case "modifiedAt":
                modifiedAt = dateFormatter.date(from: value)
            default:
                // Ignorar campos desconocidos (extensibilidad futura)
                break
            }
        }
        
        // Validar que tenemos todos los campos requeridos
        guard let id = id,
              let title = title,
              let createdAt = createdAt,
              let modifiedAt = modifiedAt else {
            throw MarkdownSerializerError.invalidFrontmatter(
                "Frontmatter incompleto o inválido. Campos requeridos: id, title, createdAt, modifiedAt"
            )
        }
        
        return (id, title, createdAt, modifiedAt)
    }
    
    // MARK: - YAML Escaping
    
    /// Escapa caracteres especiales para YAML
    ///
    /// **Reglas:**
    /// - Si contiene `:` o `"` → envolver en comillas
    /// - Escapar comillas internas: `"` → `\"`
    ///
    /// - Parameter string: String a escapar
    /// - Returns: String escapado para YAML
    nonisolated private func escapeYAML(_ string: String) -> String {
        // Si contiene caracteres especiales, envolver en comillas
        if string.contains(":") || string.contains("\"") || string.contains("\n") {
            let escaped = string.replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(escaped)\""
        }
        return string
    }
    
    /// Remueve escape de YAML
    ///
    /// - Parameter string: String escapado
    /// - Returns: String original
    nonisolated private func unescapeYAML(_ string: String) -> String {
        var result = string
        
        // Remover comillas externas
        if result.hasPrefix("\"") && result.hasSuffix("\"") {
            result = String(result.dropFirst().dropLast())
        }
        
        // Desescapar comillas internas
        result = result.replacingOccurrences(of: "\\\"", with: "\"")
        
        return result
    }
}

// MARK: - Errors

/// Errores de serialización/deserialización de Markdown
enum MarkdownSerializerError: Error, LocalizedError {
    case invalidFrontmatter(String)
    case invalidFormat(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFrontmatter(let message):
            return "Frontmatter inválido: \(message)"
        case .invalidFormat(let message):
            return "Formato inválido: \(message)"
        }
    }
}

// MARK: - Extensions

extension MarkdownSerializer {
    /// Valida si un string tiene formato Markdown válido con frontmatter
    nonisolated func isValidMarkdown(_ markdown: String) -> Bool {
        do {
            _ = try deserialize(markdown)
            return true
        } catch {
            return false
        }
    }
    
    /// Extrae solo el contenido (sin frontmatter)
    nonisolated func extractContent(from markdown: String) -> String {
        splitFrontmatter(from: markdown).content
    }
    
    /// Extrae solo el frontmatter
    nonisolated func extractFrontmatter(from markdown: String) -> String {
        splitFrontmatter(from: markdown).frontmatter
    }
}
