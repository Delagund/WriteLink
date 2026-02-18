// Singleton: Solo una instancia en toda la app
@MainActor
final class DIContainer {
    
    // PASO 1: Hacer que sea Singleton
    static let shared = DIContainer()
    
    // Serializer compartido (inmutable)
    private let markdownSerializer = MarkdownSerializer()
    
    // PAso 2: Reposoitorio Base
    /// Instancia del repositorio que se crea en el primer acceso.
    /// Tipo abstracto para cambiar el repositorio en cualquier momento sin tocar la propiedad
    private(set) lazy var noteRepository: NoteRepositoryProtocol = {
        do {
            return try NoteRepository(markdownSerializer: markdownSerializer)
        } catch {
            fatalError("❌ No se pudo inicializar NoteRepository: \(error)")
        }
    } ()
    
    // PASO 3: Use Cases (dependen del repository)
    private(set) lazy var createNoteUseCase: CreateNoteUseCase = {
        CreateNoteUseCase(repository: noteRepository)
    }()
    
    private(set) lazy var editNoteUseCase: EditNoteUseCase = {
        EditNoteUseCase(repository: noteRepository)
    }()
    
    private(set) lazy var deleteNoteUseCase: DeleteNoteUseCase = {
        DeleteNoteUseCase(repository: noteRepository)
    }()
    
    // PASO 4A: Factory method para NoteListViewModel
    func makeNoteListViewModel() -> NoteListViewModel {
        NoteListViewModel(
            repository: noteRepository,
            createUseCase: createNoteUseCase,
            editUseCase: editNoteUseCase,
            deleteUseCase: deleteNoteUseCase
        )
    }
    
    // PASO 4B: Factory method para NoteEditorViewModel (nota existente)
    func makeNoteEditorViewModel(for note: Note) -> NoteEditorViewModel {
        NoteEditorViewModel(
            note: note,
            createUseCase: createNoteUseCase,
            editUseCase: editNoteUseCase,
            deleteUseCase: deleteNoteUseCase
        )
    }
    
    // PASO 4C: Factory method para NoteEditorViewModel (nota nueva)
    func makeNoteEditorViewModel() -> NoteEditorViewModel {
        NoteEditorViewModel(
            createUseCase: createNoteUseCase,
            editUseCase: editUseCase,
            deleteUseCase: deleteNoteUseCase
        )
    }
    private init() {
        // Inicialización vacía por ahora
    }
}

// MARK: - Testing Support

#if DEBUG
extension DIContainer {
    /// Crea un contenedor de pruebas con dependencias mockeadas
    ///
    /// **Uso en tests:**
    /// ```swift
    /// let testContainer = DIContainer.makeTestContainer(
    ///     mockRepository: MockNoteRepository()
    /// )
    /// let viewModel = testContainer.makeNoteListViewModel()
    /// ```
    ///
    /// - Parameter mockRepository: Repository mockeado para testing
    /// - Returns: Container configurado para testing
    static func makeTestContainer(
        mockRepository: NoteRepositoryProtocol? = nil
    ) -> DIContainer {
        let container = DIContainer()
        
        // Si se provee un mock, reemplazar el repository
        if let mock = mockRepository {
            // Nota: Necesitarías hacer noteRepository writable para esto
            // O usar un patrón diferente (ej: protocol para el container)
            // container.noteRepository = mock
        }
        
        return container
    }
}
#endif
