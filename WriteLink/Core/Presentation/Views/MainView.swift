//
//  MainView.swift
//  WriteLink
//
//  Created by Cristian on 15-02-26.
//

import SwiftUI

/// Vista principal de la aplicación (layout de tres columnas).
///
/// **Layout:**
/// - Sidebar: Lista de notas con búsqueda
/// - Editor: Edición de la nota seleccionada
///
/// **Coordinación:**
/// - Lista → Selección → Actualiza editor
/// - Editor → Guardar → Actualiza lista
struct MainView: View {
    
    // MARK: - Properties
    
    @StateObject private var listViewModel: NoteListViewModel
    @State private var editorViewModel: NoteEditorViewModel?
    
    // MARK: - Initialization
    
    init() {
        let container = DIContainer.shared
        _listViewModel = StateObject(wrappedValue: container.makeNoteListViewModel())
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationSplitView {
            // Sidebar: Lista de notas
            VStack(spacing: 0) {
                // Toolbar superior
                toolbar
                
                // Lista
                NoteListView(viewModel: listViewModel) { note in
                    // Callback: Al seleccionar nota
                    selectNote(note)
                } onCreateNote: {
                    // Callback: Al crear nota nueva
                    if let selected = listViewModel.selectedNote {
                        selectNote(selected)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 250, ideal: 300)
        } detail: {
            // Editor: Nota seleccionada
            if let editorViewModel {
                EditorView(viewModel: editorViewModel) { savedNote in
                    // Callback: Al guardar nota
                    listViewModel.updateNote(savedNote)
                } onDelete: {
                    // Callback: Al eliminar nota
                    if let note = editorViewModel.note {
                        Task {
                            await listViewModel.deleteNote(note)
                        }
                    }
                    self.editorViewModel = nil
                }
            } else {
                emptyEditorView
            }
        }
    }
    
    // MARK: - Subviews
    
    private var toolbar: some View {
        HStack {
            Text("Notas")
                .font(.headline)
            
            Spacer()
            
            Button {
                Task {
                    await listViewModel.createNewNote()
                    if let newNote = listViewModel.selectedNote {
                        selectNote(newNote)
                    }
                }
            } label: {
                Image(systemName: "square.and.pencil")
            }
            .buttonStyle(.plain)
            .help("Nueva Nota")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private var emptyEditorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("Selecciona una nota para comenzar")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Button("Crear Nueva Nota") {
                Task {
                    await listViewModel.createNewNote()
                    if let newNote = listViewModel.selectedNote {
                        selectNote(newNote)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Methods
    
    private func selectNote(_ note: Note) {
        let container = DIContainer.shared
        editorViewModel = container.makeNoteEditorViewModel(for: note)
    }
}

// MARK: - Preview

#Preview {
    MainView()
        .frame(width: 1000, height: 700)
}
