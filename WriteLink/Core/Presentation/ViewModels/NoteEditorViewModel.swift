import Foundation
import Combine

/// ViewModel para el editor de una nota individual.
///
/// **Patrón MVVM:**
/// - View ← observa → ViewModel ← coordina → Use Cases
/// - Maneja estado de UI (loading, error, success)
/// - Transforma datos del dominio a formato UI-friendly
///
/// **Responsabilidades:**
/// 1. Exponer estado observable para SwiftUI (@Published)
/// 2. Coordinar Use Cases (crear, editar, guardar)
/// 3. Manejo de errores con mensajes user-friendly
/// 4. Debouncing de auto-save (Fase 2)
///
/// **Swift 6 Concurrency:**
/// - @MainActor: Todas las propiedades se actualizan en el main thread
/// - Garantiza que SwiftUI no tiene race conditions
@MainActor
final class NoteEditorViewModel: ObservableObject {
    
    // MARK: - Published Properties (Estado Observable)
    
    /// Nota actual siendo editada
    @Published var note: Note
    
    /// Título editable (binding bidireccional con TextField)
    @Published var title: String
    
    /// Contenido editable (binding con TextEditor)
    @Published var content: String
    
    /// Estado de carga (guardar, cargar)
    @Published var isLoading = false
    
    /// Mensaje de error para mostrar en UI
    @Published var errorMessage: String?
    
    /// Indica si hay cambios sin guardar
    @Published var hasUnsavedChanges = false
    
    // MARK: - Dependencies (Use Cases)
    
    private let createUseCase: CreateNoteUseCase
    private let editUseCase: EditNoteUseCase
    private let deleteUseCase: DeleteNoteUseCase
    
    // MARK: - Private Properties
    
    /// Almacena subscripciones de Combine
    private var cancellables = Set<AnyCancellable>()
    
    /// Referencia a la versión guardada (para detectar cambios)
    private var savedNote: Note
    
    // MARK: - Initialization
    
    /// Inicializa el ViewModel con una nota existente (modo edición)
    init(
        note: Note,
        createUseCase: CreateNoteUseCase,
        editUseCase: EditNoteUseCase,
        deleteUseCase: DeleteNoteUseCase
    ) {
        self.note = note
        self.savedNote = note
        self.title = note.title
        self.content = note.content
        self.createUseCase = createUseCase
        self.editUseCase = editUseCase
        self.deleteUseCase = deleteUseCase
        
        setupChangeDetection()
    }
    
    /// Inicializa el ViewModel para crear una nueva nota
    convenience init(
        createUseCase: CreateNoteUseCase,
        editUseCase: EditNoteUseCase,
        deleteUseCase: DeleteNoteUseCase
    ) {
        let newNote = Note.empty()
        self.init(
            note: newNote,
            createUseCase: createUseCase,
            editUseCase: editUseCase,
            deleteUseCase: deleteUseCase
        )
    }
    
    // MARK: - Setup
    
    /// Configura la detección automática de cambios
    private func setupChangeDetection() {
        // Observar cambios en title y content
        Publishers.CombineLatest($title, $content)
            .dropFirst() // Ignorar valores iniciales
            .sink { [weak self] newTitle, newContent in
                guard let self = self else { return }
                self.hasUnsavedChanges = (
                    newTitle != self.savedNote.title ||
                    newContent != self.savedNote.content
                )
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods (Actions)
    
    /// Guarda la nota (crea o actualiza según el estado)
    func save() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if note.id == savedNote.id && savedNote.isEmpty {
                // Crear nueva nota
                note = try await createUseCase.execute(
                    title: title,
                    content: content
                )
            } else {
                // Actualizar existente
                note = try await editUseCase.execute(
                    id: note.id,
                    newTitle: title,
                    newContent: content
                )
            }
            
            // Actualizar referencia guardada
            savedNote = note
            hasUnsavedChanges = false
            
        } catch let error as UseCaseError {
            errorMessage = error.localizedDescription
        } catch let error as RepositoryError {
            errorMessage = "Error al guardar: \(error.localizedDescription)"
        } catch {
            errorMessage = "Error desconocido: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Elimina la nota actual
    func delete() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await deleteUseCase.execute(id: note.id)
            isLoading = false
            return true // Éxito
        } catch {
            errorMessage = "Error al eliminar: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Descarta cambios no guardados
    func discardChanges() {
        title = savedNote.title
        content = savedNote.content
        hasUnsavedChanges = false
        errorMessage = nil
    }
    
    /// Actualiza el título y marca cambios
    func updateTitle(_ newTitle: String) {
        title = newTitle
    }
    
    /// Actualiza el contenido y marca cambios
    func updateContent(_ newContent: String) {
        content = newContent
    }
}

// MARK: - Computed Properties

extension NoteEditorViewModel {
    /// Indica si es una nota nueva (no guardada aún)
    var isNewNote: Bool {
        savedNote.isEmpty
    }
    
    /// Texto para el botón de guardar
    var saveButtonTitle: String {
        isNewNote ? "Crear Nota" : "Guardar Cambios"
    }
}
