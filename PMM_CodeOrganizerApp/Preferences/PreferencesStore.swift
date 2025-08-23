//
//  PreferencesStore.swift
//  PMM_CodeOrganizer
//
//  Created by Pedro M Moreno.
//

import Foundation
import PMM_CodeOrganizerCore

final class PreferencesStore: ObservableObject {
    private let suite = "group.com.tu.dominio.pmm-codeorganizer"
    private let key = "prefs"
    @Published var prefs = OrganizerPrefs()
    
    init() { load() }
    
    func load() {
        let ud = UserDefaults(suiteName: suite)
        if let data = ud?.data(forKey: key),
           let decoded = try? JSONDecoder().decode(
            OrganizerPrefs.self,
            from: data
           ) {
            self.prefs = decoded
        }
    }
    
    func save() {
        let ud = UserDefaults(suiteName: suite)
        if let data = try? JSONEncoder().encode(prefs) {
            ud?.set(data, forKey: key)
        }
    }
}
