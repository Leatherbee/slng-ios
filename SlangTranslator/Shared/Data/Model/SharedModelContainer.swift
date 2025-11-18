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
        let schema = Schema([
            TranslationModel.self,
            SlangModel.self
        ])
        
        let appGroupID = "group.canquinee.SLNG"
        
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("Cannot find AppGroup")
        }
        
        let storeURL = appGroupURL.appendingPathComponent("translations.sqlite")
        let config = ModelConfiguration(url: storeURL, allowsSave: true)
        
        do  {
            self.container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var context: ModelContext {
        container.mainContext
    }
}

