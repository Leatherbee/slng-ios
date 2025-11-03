//
//  DictionaryView.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 21/10/25.
//

import SwiftUI
import AVFoundation

struct DictionaryView: View {
    @StateObject private var viewModel = DictionaryViewModel()
    @Environment(PopupManager.self) private var popupManager
    private let indexWord = "abcdefghijklmnopqrstuvwxyz"
    
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                // MARK: - Picker Section
                slangPickerView()
                
                // MARK: - Alphabet Sidebar
                alphabetSidebar
            }
            
            // MARK: - Search Bar
            searchBar
                .padding(.top, -80)
        }
        .padding(.top, -20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.Background.primary)
    }
}

// MARK: - Subviews
extension DictionaryView {
    
    @ViewBuilder
    private func slangPickerView() -> some View {
        let slangs = viewModel.filteredSlangs.map { $0.slang }
        
        if !slangs.isEmpty {
            LargeWheelPicker(
                selection: $viewModel.selectedIndex,
                viewModel: self.viewModel,
                popupManager: self.popupManager,
                data: slangs
                
            )
            .frame(maxWidth: .infinity)
            .frame(height: 800) 
            
        } else {
            Text("No results")
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, maxHeight: 800)
        }
    }
    
    private var alphabetSidebar: some View {
        let letters: [String] = (97...122).compactMap { String(UnicodeScalar($0)) }
        
        return VStack(spacing: 0) {
            ForEach(letters, id: \.self) { letter in
                AlphabetLetterView(
                    letter: letter,
                    isActive: viewModel.isLetterActive(letter),
                    isDragging: viewModel.dragActiveLetter == letter
                )
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    let y = gesture.location.y
                    let index = Int((y / 18).rounded(.down))
                    if index >= 0 && index < letters.count {
                        viewModel.handleLetterDrag(letters[index])
                    }
                }
                .onEnded { _ in
                    viewModel.handleLetterDragEnd()
                }
        )
        .padding(.trailing, 6)
    }
    
    private struct AlphabetLetterView: View {
        let letter: String
        let isActive: Bool
        let isDragging: Bool
        
        var body: some View {
            Text(letter.uppercased())
                .font(.system(size: 11, design: .serif))
                .foregroundColor(isActive ? AppColor.Button.Text.primary : AppColor.Text.secondary)
                .frame(width: 20, height: 18)
                .background(
                    Circle()
                        .fill(isActive ? AppColor.Text.primary : .clear)
                )
                .scaleEffect(isDragging ? 2.0 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isDragging)
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .frame(width: 17)
                .foregroundColor(.gray)
            
            TextField("Search", text: $viewModel.searchText)
                .autocapitalization(.none)
                .padding(.vertical, 8)
                .font(.caption)
                .frame(height: 22)
                .frame(maxWidth: .infinity)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.16))
        .cornerRadius(100)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

struct LargeWheelPicker: View {
    @Binding var selection: Int
    let viewModel: DictionaryViewModel
    let popupManager: PopupManager
    let data: [String]
    
    @State private var scrollOffset: CGFloat = 0
    @State private var audioPlayer: AVAudioPlayer?
    
    private let rowHeight: CGFloat = 75
    private let visibleCount: Int = 5
    
    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: (geo.size.height - rowHeight) / 2)
                        ForEach(data.indices, id: \.self) { index in
                            item(for: index, geometry: geo)
                                .frame(height: rowHeight)
                                .id(index)
                        }
                        Spacer().frame(height: (geo.size.height - rowHeight) / 2)
                    }
                    .background(
                        GeometryReader { innerGeo in
                            Color.clear.preference(
                                key: ScrollOffsetKey.self,
                                value: innerGeo.frame(in: .named("scroll")).minY
                            )
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetKey.self) { value in
                    scrollOffset = value
                    updateSelection(geometry: geo)
                }
                .onChange(of: selection) { newValue in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
                .gesture(
                    DragGesture()
                        .onEnded { _ in
                            let centerOffset = scrollOffset + (geo.size.height / 2)
                            let targetIndex = Int((centerOffset / rowHeight).rounded(.down))
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                proxy.scrollTo(targetIndex, anchor: .center)
                            }
                            selection = max(0, min(targetIndex, data.count - 1))
                            playClickSound()
                        }
                )
                .onAppear {
                    prepareSound()
                    proxy.scrollTo(selection, anchor: .center)
                }
            }
        }
        .frame(height: 620)
    }
    
    // MARK: - Item Appearance
    private func item(for index: Int, geometry: GeometryProxy) -> some View {
        GeometryReader { itemGeo in
            let itemCenter = itemGeo.frame(in: .global).midY
            let viewCenter = geometry.frame(in: .global).midY
            let distance = abs(itemCenter - viewCenter)
            let maxDistance: CGFloat = 150
            
            // Scale and opacity based on distance
            let normalized = min(distance / maxDistance, 1)
            let scale = 1.0 - (normalized * 0.4)
            let opacity = 1.0 - (normalized * 0.6)
            if selection == index{
                Button{
                    if let slangData = viewModel.getSlang(at: viewModel.selectedIndex) {
                        popupManager.setSlangData(slangData)
                        popupManager.isPresented.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(data[index])
                            .font(.system(size: 64, weight: .medium))
                            .scaleEffect(scale)
                            .opacity(opacity)
                            .foregroundColor(AppColor.Text.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .allowsTightening(true)
                        
                        if selection == index {
                            Image("arrowHome")
                                .resizable()
                                .frame(width: 64, height: 18)
                                .tint(AppColor.Text.primary)
                                .transition(.opacity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())                }
                
            } else {
                HStack(spacing: 4) {
                    Text(data[index])
                        .font(.system(size: 64, weight: .medium))
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .foregroundColor(AppColor.Text.primary)
                        .lineLimit(1)
                    
                    if selection == index {
                        Image("arrowHome")
                            .resizable()
                            .frame(width: 64, height: 18)
                            .tint(AppColor.Text.primary)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = index
                    }
                    playClickSound()
                }
            }
            
        }
        .frame(height: rowHeight)
    }
    
    // MARK: - Selection Calculation
    private func updateSelection(geometry: GeometryProxy) {
        let centerOffset = scrollOffset + (geometry.size.height / 2)
        let index = Int((centerOffset / rowHeight).rounded(.down))
        guard index >= 0 && index < data.count else { return }
        
        if index != selection {
            selection = index
            playClickSound()
        }
    }
    
    // MARK: - Sound
    private func prepareSound() {
        guard let url = Bundle.main.url(forResource: "wheel_click", withExtension: "mp3") else { return }
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.prepareToPlay()
        audioPlayer?.volume = 1.0
    }
    
    private func playClickSound() {
        guard let player = audioPlayer else { return }
        player.currentTime = 0
        player.play()
    }
}

// MARK: - Scroll Offset Key
private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}



#Preview {
    DictionaryView()
        .environment(PopupManager())
}
