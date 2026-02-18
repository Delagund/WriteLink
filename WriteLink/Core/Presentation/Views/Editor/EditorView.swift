import SwiftUI

/// Vista principal del editor de notas.
///
/// **Características MVP:**
/// - Edición de título y contenido
/// - Botón de guardar con estado de carga
/// - Indicador de cambios no guardados
/// - Manejo de errores con alerts
struct EditorView: View {
    
    // MARK: - Properties
    
    @StateObject var viewModel: NoteEditorViewModel
    
    /// Callback cuando se guarda exitosamente
    var onSave: ((Note) -> Void)?
    
    /// Callback cuando se elimina
    var onDelete: (() -> Void)?
    
    // MARK: - State
    
    @State private var showingDeleteAlert = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title
        case content
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar superior
            toolbar
            
            Divider()
            
            // Editor principal
            editorContent
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .alert("Eliminar Nota", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive) {
                Task {
                    if await viewModel.delete() {
                        onDelete?()
                    }
                }
            }
        } message: {
            Text("¿Estás seguro de que quieres eliminar esta nota? Esta acción no se puede deshacer.")
        }
    }
    
    // MARK: - Subviews
    
    private var toolbar: some View {
        HStack {
            // Indicador de cambios
            if viewModel.hasUnsavedChanges {
                Label("Sin guardar", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            
            Spacer()
            
            // Botón de descartar cambios
            if viewModel.hasUnsavedChanges {
                Button("Descartar") {
                    viewModel.discardChanges()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
            
            // Botón de eliminar (solo si no es nueva)
            if !viewModel.isNewNote {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
            }
            
            // Botón de guardar
            Button {
                Task {
                    await viewModel.save()
                    if viewModel.errorMessage == nil {
                        onSave?(viewModel.note)
                    }
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(viewModel.saveButtonTitle)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading || !viewModel.hasUnsavedChanges)
        }
        .padding()
    }
    
    private var editorContent: some View {
        VStack(spacing: 0) {
            // Campo de título
            TextField("Título de la nota", text: $viewModel.title)
                .font(.title)
                .textFieldStyle(.plain)
                .focused($focusedField, equals: .title)
                .padding()
            
            Divider()
            
            // Editor de contenido (Markdown)
            TextEditor(text: $viewModel.content)
                .font(.body)
                .focused($focusedField, equals: .content)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            // Auto-focus en título si es nota nueva
            if viewModel.isNewNote {
                focusedField = .title
            }
        }
    }
}

// MARK: - Preview

#Preview("Nota Existente") {
    EditorView(
        viewModel: NoteEditorViewModel(
            note: Note.preview,
            createUseCase: CreateNoteUseCase(repository: try! NoteRepository()),
            editUseCase: EditNoteUseCase(repository: try! NoteRepository()),
            deleteUseCase: DeleteNoteUseCase(repository: try! NoteRepository())
        )
    )
}

#Preview("Nota Nueva") {
    EditorView(
        viewModel: NoteEditorViewModel(
            createUseCase: CreateNoteUseCase(repository: try! NoteRepository()),
            editUseCase: EditNoteUseCase(repository: try! NoteRepository()),
            deleteUseCase: DeleteNoteUseCase(repository: try! NoteRepository())
        )
    )
}
