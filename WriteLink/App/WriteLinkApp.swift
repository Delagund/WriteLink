//
//  WriteLinkApp.swift
//  WriteLink
//
//  Created by Cristian on 28-01-26.
//  Entry point

import SwiftUI

@main
struct WriteLinkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()       // TODO: reemplazar por un MainView() si existe
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
                .commands {
                    // Comandos de menú (Fase 2)
                    CommandGroup(replacing: .newItem) {
                        Button("Nueva Nota") {
                            // TODO: Implementar con NotificationCenter
                        }
                        .keyboardShortcut("n", modifiers: .command)
                    }
                }
    }
}
