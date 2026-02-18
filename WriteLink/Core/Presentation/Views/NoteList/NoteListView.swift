import SwiftUI

/// Vista de lista de notas con búsqueda.
///
/// **Características MVP:**
/// - Lista de notas ordenadas por modificación
/// - Barra de búsqueda con debouncing
/// - Selección de nota
/// - Botón para crear nueva nota
struct NoteListView: View {
    
    // MARK: - Properties
    
    @StateObject var viewModel: NoteListViewModel
    
    /// Callback cuando se selecciona una nota
    var onSelectNote: ((Note) -> Void)?
    
    /// Callback cuando se crea una nueva nota
    var onCreateNote: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Barra de búsqueda
            searchBar
            
            Divider()
            
            // Lista de notas
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredNotes.isEmpty {
                emptyStateView
            } else {
                notesList
            }
        }
        .task {
            await viewModel.loadNotes()
        }
    }
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Buscar notas...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
            
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private var notesList: some View {
        List(viewModel.filteredNotes, selection: $viewModel.selectedNote) { note in
            NoteRowView(note: note)
                .tag(note)
                .onTapGesture {
                    viewModel.selectNote(note)
                    onSelectNote?(note)
                }
                .contextMenu {
                    Button("Eliminar", role: .destructive) {
                        Task {
                            await viewModel.deleteNote(note)
                        }
                    }
                }
        }
        .listStyle(.sidebar)
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("Cargando notas...")
                .foregroundStyle(.secondary)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text(viewModel.searchQuery.isEmpty ? "No hay notas" : "No se encontraron notas")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            if viewModel.searchQuery.isEmpty {
                Button("Crear Primera Nota") {
                    Task {
                        await viewModel.createNewNote()
                        onCreateNote?()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Note Row View

/// Celda individual de la lista de notas.
struct NoteRowView: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title)
                .font(.headline)
                .lineLimit(1)
            
            Text(contentPreview)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            Text(note.updatedAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
    
    private var contentPreview: String {
        let preview = note.content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
        
        return preview.isEmpty ? "Nota vacía" : preview
    }
}

// MARK: - Preview

#Preview {
    NoteListView(
        viewModel: {
            let container = DIContainer.shared
            let vm = container.makeNoteListViewModel()
            // Simular notas cargadas
            vm.notes = [
                Note.preview,
                Note(title: "Segunda Nota", content: "Contenido de prueba"),
                Note(title: "Tercera Nota", content: "Más contenido")
            ]
            return vm
        }()
    )
    .frame(width: 300, height: 600)
}
