//
//  TashSlangDictionary.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 29/10/25.
//
import SwiftUI
import AudioToolbox


struct TashSlangDictionary: View {
    // Ambil semua slang dan urutkan abjad
    let allSlangs: [SlangData] = Array(SlangDictionary.shared.slangs.values)
        .sorted { $0.slang.lowercased() < $1.slang.lowercased() }
    
    @State private var indexSelect: Int = 0
    
    var body: some View {
        TrashSlang(
            data: allSlangs.map { $0.slang },
            indexSelect: $indexSelect
        )
    }
}

struct TrashSlang: View {
    let data: [String]
    @Binding var indexSelect: Int
    var itemHeight: CGFloat = 50
    var soundId: SystemSoundID = 1127
    
    @State private var dragOffset: CGFloat = 0
    @State private var lastIndex: Int = 0
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer()
                
                // Wheel-like ScrollView
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(data.indices, id: \.self) { i in
                            Text(data[i])
                                .font(.system(size: i == indexSelect ? 32 : 22, weight: .medium))
                                .frame(height: itemHeight)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(i == indexSelect ? .primary : .gray)
                                .scaleEffect(i == indexSelect ? 1.15 : 1)
                        }
                    }
                    .padding(.vertical, geo.size.height / 2 - itemHeight / 2)
                    .background(
                        GeometryReader { innerGeo in
                            Color.clear.preference(
                                key: ScrollOffsetKey.self,
                                value: innerGeo.frame(in: .named("scroll")).origin.y
                            )
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetKey.self) { value in
                    // Hitung posisi relatif scroll
                    let offset = -value
                    let rawIndex = (offset / itemHeight).rounded()
                    let newIndex = max(0, min(data.count - 1, Int(rawIndex)))
                    
                    if newIndex != indexSelect {
                        indexSelect = newIndex
                        AudioServicesPlaySystemSound(soundId)
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.height
                        }
                        .onEnded { value in
                            let predictedEnd = value.predictedEndTranslation.height
                            let newIndex = Int((CGFloat(indexSelect) - predictedEnd / itemHeight).rounded())
                            indexSelect = max(0, min(data.count - 1, newIndex))
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                )
                
                Spacer()
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    .frame(height: itemHeight)
            )
        }
    }
}

// Preference key untuk membaca offset
private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    TashSlangDictionary()
}

