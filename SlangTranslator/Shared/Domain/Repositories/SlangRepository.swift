//
//  SlangRepository.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 04/11/25.
//

import Foundation

protocol SlangRepository {
    func loadAll() -> [SlangData]
}
