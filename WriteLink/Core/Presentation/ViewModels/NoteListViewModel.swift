// Core/Presentation/ViewModels/NoteListViewModel.swift

import Foundation
import Combine

/// ViewModel para la lista de notas con búsqueda.
///
/// **Responsabilidades:**
/// - Cargar todas las notas desde el repositorio
/// - Filtrar notas según búsqueda
/// - Manejar selección de nota
/// - Coordinar creación de nuevas notas
@MainActor
final class NoteListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Todas las notas cargadas
    @Published var notes: [Note] = []
    
    /// Notas filtradas por búsqueda
    @Published var filteredNotes: [Note] = []
    
    /// Texto de búsqueda
    @Published var searchQuery: String = ""
    
    /// Nota seleccionada actualmente
    @Published var selectedNote: Note?
    
    /// Estado de carga
    @Published var isLoading = false
    
    /// Mensaje de error
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let createUseCase: CreateNoteUseCase
    private let editUseCase: EditNoteUseCase
    private let deleteUseCase: DeleteNoteUseCase
    private let repository: NoteRepositoryProtocol
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        repository: NoteRepositoryProtocol,
        createUseCase: CreateNoteUseCase,
        editUseCase: EditNoteUseCase,
        deleteUseCase: DeleteNoteUseCase
    ) {
        self.repository = repository
        self.createUseCase = createUseCase
        self.editUseCase = editUseCase
        self.deleteUseCase = deleteUseCase
        
        setupSearchBinding()
    }
    
    // MARK: - Setup
    
    /// Configura el binding de búsqueda con debouncing
    private func setupSearchBinding() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.filterNotes(with: query)
            }
            .store(in: &cancellables)
        
        // Observar cambios en notes para actualizar filteredNotes
        $notes
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.filterNotes(with: self.searchQuery)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Carga todas las notas desde el repositorio
    func loadNotes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            notes = try await repository.getAll()
        } catch {
            errorMessage = "Error al cargar notas: \(error.localizedDescription)"
            notes = []
        }
        
        isLoading = false
    }
    
    /// Crea una nueva nota y la selecciona
    func createNewNote() async {
        let newNote = Note.empty()
        selectedNote = newNote
        
        // Agregar temporalmente a la lista (se guardará al editar)
        notes.insert(newNote, at: 0)
    }
    
    /// Elimina una nota de la lista
    func deleteNote(_ note: Note) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await deleteUseCase.execute(id: note.id)
            
            // Remover de la lista local
            notes.removeAll { $0.id == note.id }
            
            // Deseleccionar si estaba seleccionada
            if selectedNote?.id == note.id {
                selectedNote = nil
            }
        } catch {
            errorMessage = "Error al eliminar: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Actualiza una nota en la lista local
    func updateNote(_ updatedNote: Note) {
        if let index = notes.firstIndex(where: { $0.id == updatedNote.id }) {
            notes[index] = updatedNote
        } else {
            // Nota nueva, agregarla
            notes.insert(updatedNote, at: 0)
        }
        
        // Actualizar selección
        if selectedNote?.id == updatedNote.id {
            selectedNote = updatedNote
        }
    }
    
    /// Selecciona una nota
    func selectNote(_ note: Note) {
        selectedNote = note
    }
    
    // MARK: - Private Methods
    
    /// Filtra notas según el query de búsqueda
    private func filterNotes(with query: String) {
        if query.isEmpty {
            filteredNotes = notes
        } else {
            let lowercasedQuery = query.lowercased()
            filteredNotes = notes.filter { note in
                note.title.lowercased().contains(lowercasedQuery) ||
                note.content.lowercased().contains(lowercasedQuery)
            }
        }
    }
}

// MARK: - Computed Properties

extension NoteListViewModel {
    /// Indica si hay notas para mostrar
    var hasNotes: Bool {
        !notes.isEmpty
    }
    
    /// Número de notas filtradas
    var noteCount: Int {
        filteredNotes.count
    }
}
