//
//  PreferencesView.swift
//  PMM_CodeOrganizer
//
//  Created by Pedro M Moreno.
//

import SwiftUI

struct PreferencesView: View {
    @StateObject private var store = PreferencesStore()

    var body: some View {
        Form {
            Section("Behaviors") {
                Toggle("Sort imports", isOn: $store.prefs.sortImports)
                Toggle("Insert // MARK: sections", isOn: $store.prefs.insertMarks)
                Toggle("Reorder members (risky)", isOn: $store.prefs.reorderMembers)
                Toggle("Reorder top-level decls", isOn: $store.prefs.reorderTopLevel)
            }
            Section("Limits") {
                Stepper("Max function lines: \(store.prefs.maxFunctionLines)", value: $store.prefs.maxFunctionLines, in: 20...1000)
                Stepper("Max type lines: \(store.prefs.maxTypeLines)", value: $store.prefs.maxTypeLines, in: 50...5000)
            }
            Button("Save") { store.save() }
        }
        .padding()
    }
}
