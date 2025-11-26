//
//  SharedModelContainer.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 25/10/25.
//

import Foundation
import SwiftData

@MainActor
final class SharedModelContainer {
    static let shared = SharedModelContainer()
    
    let container: ModelContainer
    
    private init() {
        let appGroupID = "group.prammmoe.SLNG"
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("Cannot find AppGroup")
        }
        let storeURL = appGroupURL.appendingPathComponent("translations.sqlite")
        let schemaLatest = Schema(versionedSchema: SLNGSchemaLatest.self)
        let config = ModelConfiguration(schema: schemaLatest, url: storeURL, allowsSave: true)
        do {
            self.container = try ModelContainer(for: schemaLatest, migrationPlan: SLNGMigrationPlan.self, configurations: [config])
        } catch {
            do {
                let schemaV1 = Schema(versionedSchema: SLNGSchemaV1.self)
                let configV1 = ModelConfiguration(schema: schemaV1, url: storeURL, allowsSave: true)
                _ = try ModelContainer(for: schemaV1, configurations: [configV1])
                self.container = try ModelContainer(for: schemaLatest, migrationPlan: SLNGMigrationPlan.self, configurations: [config])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }
    
    var context: ModelContext {
        container.mainContext
    }
}
