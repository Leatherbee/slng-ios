//
//  DictionaryView.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 21/10/25.
//

import SwiftUI
import AVFoundation
import SwiftData
internal import Combine
struct DictionaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PopupManager.self) private var popupManager
    @StateObject private var viewModel: DictionaryViewModel
    let letters: [String] = (97...122).compactMap { String(UnicodeScalar($0)) }
    init() {
        let context = ModelContext(SharedModelContainer.shared.container)
        _viewModel = StateObject(wrappedValue: DictionaryViewModel(context: context))
    }
    @State var letterActive: String = "g"
    private let indexWord = "abcdefghijklmnopqrstuvwxyz"
    
    var body: some View {
        ZStack(alignment: .topLeading){
            VStack(spacing: 0){
              
                VStack {
                    HStack(alignment: .center) {
                        slangPickerView()
                        alphabetSidebar
                    }
                    
                }
                
                VStack {
                    VStack{
                        searchBar
                            .keyboardAdaptive()
                    }
                    .background(AppColor.Background.primary)
                    .padding(.top, -220)
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.clear)
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.Background.primary)
            VStack{
                Text(activeLetter) .font(.system(size: 64, design: .serif))
                   
                    .foregroundColor(AppColor.Text.secondary)
                    .id(activeLetter)
                    .transition(.opacity.combined(with: .scale))
                    .animation(.easeInOut(duration: 0.25), value: activeLetter)
            }
            .padding(.top, 150)
            .padding(.leading)
          
        }
        
  
    }
}
struct KeyboardAdaptive: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    private var keyboardPublisher: AnyPublisher<CGFloat, Never> {
        Publishers.Merge(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
                .map { $0.height },
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in CGFloat(0) }
        ).eraseToAnyPublisher()
    }

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onReceive(keyboardPublisher) { self.keyboardHeight = $0 }
            .animation(.easeOut(duration: 0.25), value: keyboardHeight)
    }
}

extension View {
    func keyboardAdaptive() -> some View {
        self.modifier(KeyboardAdaptive())
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
                viewModel: viewModel,
                popupManager: popupManager,
                data: slangs
            )
            .frame(maxWidth: .infinity)
            .frame(height: 1000)
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
                    if (0..<letters.count).contains(index) {
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
                    Circle().fill(isActive ? AppColor.Text.primary : .clear)
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
        .background(Color.gray.opacity(0.32))
        .cornerRadius(100)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    var activeLetter: String {
        guard viewModel.selectedIndex < viewModel.filteredSlangs.count else { return "" }
        return String(viewModel.filteredSlangs[viewModel.selectedIndex].slang.prefix(1).uppercased())
       }
}

struct LargeWheelPicker: View {
    @Binding var selection: Int
    let viewModel: DictionaryViewModel
    let popupManager: PopupManager
    let data: [String]
    @State private var audioPlayer: AVAudioPlayer?
    private let rowHeight: CGFloat = 80
    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    GeometryReader { scrollGeo in
                        Color.clear
                            .preference(key: ScrollOffsetKey.self, value: scrollGeo.frame(in: .global).minY)
                    }
                    .frame(height: 0)
                    LazyVStack(spacing: 16) {
                        ForEach(data.indices, id: \.self) { index in
                            item(for: index, geometry: geo)
                                .frame(height: rowHeight)
                                .id(index)
                        }
                    }
                }
                .onPreferenceChange(ScrollOffsetKey.self) { _ in
                    updateSelection(geometry: geo) }
                .onChange(of: selection) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        proxy.scrollTo(selection, anchor: .center)
                    }
                }
                .onAppear {
                    prepareSound()
                    proxy.scrollTo(selection, anchor: .center)
                }
            }
        }
        .frame(height: 700)
    }
    
    private func updateSelection(geometry: GeometryProxy) {
        // Ambil semua posisi item
        let viewCenter = geometry.frame(in: .global).midY // Cari index yang paling dekat ke tengah
        var closestIndex: Int?
        var minDistance: CGFloat = .infinity
        for index in data.indices {
            let itemY = geometry.frame(in: .global).minY + CGFloat(index) * rowHeight + (rowHeight / 2)
            let distance = abs(itemY - viewCenter)
            if distance < minDistance {
                minDistance = distance
                closestIndex = index
            }
        } // Update selectedIndex kalau berubah
        if let newIndex = closestIndex, newIndex != selection {
            selection = newIndex
            viewModel.selectedIndex = newIndex
        }
    } // MARK: - Item View
    private func item(for index: Int, geometry: GeometryProxy) -> some View {
        GeometryReader { itemGeo in
            let itemCenter = itemGeo.frame(in: .global).midY
            let viewCenter = geometry.frame(in: .global).midY
            let distance = abs(itemCenter - viewCenter)
            let normalized = min(distance / 150, 1)
            let scale = 1.0 - (normalized * 0.4)
            let opacity = 1.0 - (normalized * 0.6)
            let isFocused = scale > 0.9
            
            // Tentukan tinggi baris berdasarkan scale
            let dynamicHeight: CGFloat = {
                switch scale {
                case ..<0.6:
                    return 0
                case 0.6..<0.7:
                    return 0
                case 0.7..<0.9:
                    return 0
                default:
                    return 0
                }
            }()
            
            if distance < 400 {
                Button {
                    if isFocused {
                        if let slangData = viewModel.getSlang(at: index) {
                            popupManager.setSlangData(slangData)
                            popupManager.isPresented.toggle()
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selection = index
                        }
                        playClickSound()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(data[index])
                            .font(.system(size: {
                                switch scale {
                                case ...0.6: return 33
                                case 0.61...0.7: return 34
                                case 0.8...0.9: return 38
                                default: return 48
                                }
                            }(), weight: .medium, design: .serif))
                            .opacity(opacity)
                            .foregroundColor(AppColor.Text.primary)
                            .lineLimit(1)
                            .animation(.easeInOut(duration: 0.2), value: scale)
                        
                        if isFocused {
                            Image("arrowHome")
                                .resizable()
                                .frame(width: 64, height: 18)
                                .tint(AppColor.Text.primary)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .opacity
                                ))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isFocused)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onChange(of: isFocused) {
                    if isFocused {
                        playClickSound()
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        if index == data.count - 1 {
                            selection = index
                        }
                    }
                }
                .frame(height: dynamicHeight) // <— tinggi item menyesuaikan scale
            }
        }
    }

    private func prepareSound() {
        guard let url = Bundle.main.url(forResource: "picker", withExtension: "mp3") else { return }
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
