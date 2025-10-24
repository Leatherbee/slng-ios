//
//  SlangData.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 17/10/25.
//

import Foundation

struct SlangData {
    let slang: String
    let translationID: String
    let translationEN: String
    let contextID: String
    let contextEN: String
    let exampleID: String
    let exampleEN: String
}

class SlangDictionary {
    static let shared = SlangDictionary()
    
    let slangs: [String: SlangData] = [
        /// yang tidak digunakan untuk di UI adalah translationID dan contextID
        
        "gue": SlangData(
            slang: "gue",
            translationID: "saya / aku",
            translationEN: "me, I, I am",
            contextID: "Kata ganti orang pertama informal yang sangat umum di Jakarta dan sekitarnya.",
            contextEN: "A very common informal first-person pronoun in Jakarta and its surroundings.",
            exampleID: "Gue lagi sibuk nih.",
            exampleEN: "I'm busy right now."
        ),
        "lu": SlangData(
            slang: "lu",
            translationID: "kamu",
            translationEN: "you",
            contextID: "Kata ganti orang kedua informal, pasangan dari 'gue'.",
            contextEN: "An informal second-person pronoun, often paired with 'gue'.",
            exampleID: "Lu kemana aja?",
            exampleEN: "Where have you been?"
        ),
        "gokil": SlangData(
            slang: "gokil",
            translationID: "gila / keren banget",
            translationEN: "crazy / awesome",
            contextID: "Digunakan untuk mengekspresikan sesuatu yang luar biasa atau mengejutkan.",
            contextEN: "Used to express amazement or excitement; similar to 'crazy' or 'insane' in English slang.",
            exampleID: "Film itu gokil banget!",
            exampleEN: "That movie was insane!"
        ),
        "baper": SlangData(
            slang: "baper",
            translationID: "bawa perasaan",
            translationEN: "too emotional / catching feelings",
            contextID: "Ketika seseorang terlalu sensitif atau tersinggung, biasanya dalam konteks percintaan.",
            contextEN: "Used when someone is overly emotional, often in romantic situations.",
            exampleID: "Jangan baperan dong, cuma becanda.",
            exampleEN: "Don't get so emotional, I was just joking."
        ),
        "kepo": SlangData(
            slang: "kepo",
            translationID: "ingin tahu urusan orang lain",
            translationEN: "nosy / overly curious",
            contextID: "Dari 'knowing every particular object', digunakan untuk orang yang terlalu ingin tahu.",
            contextEN: "Derived from 'knowing every particular object'; refers to someone who is overly curious about others’ business.",
            exampleID: "Duh kepo banget sih lu.",
            exampleEN: "You're so nosy, dude."
        )
    ]
    
    func findSlang(in text: String) -> [SlangData] {
        let lowercased = text.lowercased()
        var found: [SlangData] = []
        
        for (key, value) in slangs {
            if lowercased.contains(key) {
                found.append(value)
            }
        }
        
        return found
    }
}

