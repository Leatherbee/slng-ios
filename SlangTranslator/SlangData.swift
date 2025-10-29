//
//  SlangData.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 17/10/25.
//

import Foundation

struct SlangData: Hashable {
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
        ),
        "mager": SlangData(
            slang: "mager",
            translationID: "malas gerak",
            translationEN: "too lazy to move",
            contextID: "Digunakan ketika seseorang terlalu malas untuk beraktivitas.",
            contextEN: "Used when someone feels too lazy to do anything.",
            exampleID: "Males ah keluar, lagi mager.",
            exampleEN: "I don’t wanna go out, I’m too lazy."
        ),
        "gabut": SlangData(
            slang: "gabut",
            translationID: "tidak ada kerjaan / bosan",
            translationEN: "bored / nothing to do",
            contextID: "Kondisi ketika seseorang merasa tidak punya kegiatan yang menarik.",
            contextEN: "A state of boredom or having nothing to do.",
            exampleID: "Lagi gabut banget nih, nonton apa ya?",
            exampleEN: "I'm so bored, what should I watch?"
        ),
        "ngab": SlangData(
            slang: "ngab",
            translationID: "bro / sobat (dari kebalikan 'bang')",
            translationEN: "bro / dude",
            contextID: "Sebutan akrab antar teman, berasal dari kata 'bang' yang dibalik.",
            contextEN: "A friendly term between friends, derived from reversing 'bang' (bro).",
            exampleID: "Woy ngab, lama banget lu!",
            exampleEN: "Yo bro, you’re so slow!"
        ),
        "santuy": SlangData(
            slang: "santuy",
            translationID: "santai",
            translationEN: "chill / relaxed",
            contextID: "Versi gaul dari 'santai', sering digunakan anak muda.",
            contextEN: "A playful form of 'relaxed', often used among youth.",
            exampleID: "Santuy aja bro, gak usah panik.",
            exampleEN: "Just chill bro, no need to panic."
        ),
        "ciyus": SlangData(
            slang: "ciyus",
            translationID: "serius",
            translationEN: "serious",
            contextID: "Versi bercanda dari kata 'serius', digunakan saat menggoda atau bercanda.",
            contextEN: "A joking way of saying 'serious'.",
            exampleID: "Ciyus nih? Gak bohong?",
            exampleEN: "Seriously? Not lying?"
        ),
        "alay": SlangData(
            slang: "alay",
            translationID: "berlebihan / norak",
            translationEN: "cringy / over-the-top",
            contextID: "Untuk menggambarkan gaya atau perilaku yang dianggap berlebihan.",
            contextEN: "Used to describe exaggerated or tacky style/behavior.",
            exampleID: "Statusnya alay banget deh.",
            exampleEN: "That status is so cringy."
        ),
        "bucin": SlangData(
            slang: "bucin",
            translationID: "budak cinta",
            translationEN: "simp / love slave",
            contextID: "Digunakan untuk seseorang yang terlalu tergila-gila pada pasangannya.",
            contextEN: "Used for someone overly obsessed or submissive in love.",
            exampleID: "Dia bucin banget sama pacarnya.",
            exampleEN: "He's such a simp for his girlfriend."
        ),
        "receh": SlangData(
            slang: "receh",
            translationID: "lelucon ringan / tidak penting",
            translationEN: "silly / lame joke",
            contextID: "Digunakan untuk candaan yang ringan atau garing.",
            contextEN: "Used for simple or corny jokes.",
            exampleID: "Wkwk receh banget tapi lucu.",
            exampleEN: "That was dumb but funny."
        ),
        "panutan": SlangData(
            slang: "panutan",
            translationID: "orang yang dikagumi / ditiru",
            translationEN: "role model / idol",
            contextID: "Sering dipakai secara sarkastik di media sosial.",
            contextEN: "Often used sarcastically to mock or praise someone online.",
            exampleID: "Waduh panutan banget kelakuannya.",
            exampleEN: "Wow, such a role model."
        ),
        "salfok": SlangData(
            slang: "salfok",
            translationID: "salah fokus",
            translationEN: "wrongly focused",
            contextID: "Digunakan ketika seseorang memperhatikan hal yang tidak penting.",
            contextEN: "Used when someone notices irrelevant details.",
            exampleID: "Aku salfok sama bajunya.",
            exampleEN: "I got distracted by the shirt."
        ),
        "ngegas": SlangData(
            slang: "ngegas",
            translationID: "marah-marah / menyerang dengan kata-kata",
            translationEN: "aggressive / snapping",
            contextID: "Digunakan saat seseorang terlalu cepat tersinggung atau marah.",
            contextEN: "Used for someone getting angry too fast.",
            exampleID: "Santai dong, jangan ngegas.",
            exampleEN: "Chill out, don’t get mad."
        ),
        "mantul": SlangData(
            slang: "mantul",
            translationID: "mantap betul",
            translationEN: "awesome / great",
            contextID: "Singkatan dari 'mantap betul', bentuk apresiasi positif.",
            contextEN: "Shortened form of 'mantap betul', means awesome.",
            exampleID: "Idenya mantul banget!",
            exampleEN: "That idea is awesome!"
        ),
        "woles": SlangData(
            slang: "woles",
            translationID: "santai",
            translationEN: "take it easy / chill",
            contextID: "Kata 'santai' yang dibalik hurufnya, populer di era 2010-an.",
            contextEN: "Reversed spelling of 'santai', popular in the 2010s.",
            exampleID: "Woles aja bro, gak usah panik.",
            exampleEN: "Take it easy bro, don’t panic."
        ),
        "julid": SlangData(
            slang: "julid",
            translationID: "iri / suka mengomentari negatif",
            translationEN: "snarky / jealous",
            contextID: "Digunakan untuk orang yang suka berkomentar pedas di media sosial.",
            contextEN: "Used for people who make snarky or jealous remarks online.",
            exampleID: "Netizennya julid banget, deh.",
            exampleEN: "The netizens are being so snarky."
        ),
        "halu": SlangData(
            slang: "halu",
            translationID: "halusinasi / berkhayal berlebihan",
            translationEN: "delusional / overly imaginative",
            contextID: "Untuk seseorang yang bermimpi terlalu jauh atau percaya hal tak nyata.",
            contextEN: "Used when someone has unrealistic dreams or beliefs.",
            exampleID: "Dia halu banget ngerasa artis suka sama dia.",
            exampleEN: "He’s so delusional thinking that celebrity likes him."
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

