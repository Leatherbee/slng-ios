////
////  DictionaryView.swift
////  SlangTranslator
////
////  Created by Filza Rizki Ramadhan on 21/10/25.
////
//
//import SwiftUI
//import AVFoundation
//import SwiftData
//internal import Combine
//struct DictionaryView: View {
//    @Environment(\.modelContext) private var modelContext
//    @Environment(PopupManager.self) private var popupManager
//    @StateObject private var viewModel: DictionaryViewModel
//    let letters: [String] = (97...122).compactMap { String(UnicodeScalar($0)) }
//    
//    init() {
//        let context = ModelContext(SharedModelContainer.shared.container)
//        _viewModel = StateObject(wrappedValue: DictionaryViewModel(context: context))
//    }
//    
//    @State var letterActive: String = "g"
//    private let indexWord = "abcdefghijklmnopqrstuvwxyz"
//    
//    var body: some View {
//        ZStack(alignment: .topLeading) {
//            VStack(spacing: 0) {
//                VStack {
//                    HStack(alignment: .center) {
//                        SlangPickerView(viewModel: viewModel)
//                        alphabetSidebar
//                    }
//                }
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .background(AppColor.Background.primary)
//            
//            VStack {
//                Text(activeLetter)
//                    .font(.system(size: 64, design: .serif))
//                    .foregroundColor(AppColor.Text.secondary)
//                    .id(activeLetter)
//                    .transition(.opacity.combined(with: .scale))
//                    .animation(.easeInOut(duration: 0.25), value: activeLetter)
//            }
//            .padding(.top, 150)
//            .padding(.leading)
//        }
//    }
//}
// 
//
//struct SlangPickerView: View {
//    @ObservedObject var viewModel: DictionaryViewModel
//
//    var body: some View {
//        VStack(spacing: 24) {
//            // Tentukan SwiftUIWheelPicker<SlangModel, AnyView>
//            SwiftUIWheelPicker<SlangModel, AnyView>(
//                items: viewModel.filteredSlangs,
//                selection: $viewModel.selectedIndex
//            ) { item, idx, isSelected in
//                let distance = abs(viewModel.selectedIndex - idx)
//
//                let (fontSize, rowHeight, opacity): (CGFloat, CGFloat, Double)
//                switch distance {
//                case 0: (fontSize, rowHeight, opacity) = (64, 76, 1.0)
//                case 1: (fontSize, rowHeight, opacity) = (48, 57, 0.8)
//                case 2: (fontSize, rowHeight, opacity) = (40, 48, 0.6)
//                case 3: (fontSize, rowHeight, opacity) = (34, 41, 0.4)
//                case 4: (fontSize, rowHeight, opacity) = (28, 33, 0.2)
//                default: (fontSize, rowHeight, opacity) = (0, 0, 0)
//                }
//
//                return AnyView(
//                    HStack(spacing: 32) {
//                        Text(item.slang)
//                            .font(.system(size: fontSize, weight: isSelected ? .bold : .medium, design: .serif))
//                            .frame(height: rowHeight)
//                            .padding(.leading, 8)
//                            .opacity(opacity)
//                            .scaleEffect(isSelected ? 1.1 : 1.0)
//                            .lineLimit(1)
//                            .truncationMode(.tail)
//                            .animation(.easeInOut(duration: 0.25), value: viewModel.selectedIndex)
//                            .layoutPriority(1)
//
//                        if isSelected {
//                            Image("arrowHome")
//                                .resizable()
//                                .frame(width: 64, height: 18)
//                                .tint(AppColor.Text.primary)
//                                .transition(.asymmetric(
//                                    insertion: .move(edge: .trailing).combined(with: .opacity),
//                                    removal: .opacity
//                                ))
//                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
//                        }
//                    }
//                    .frame(maxWidth: .infinity, alignment: .center)
//                )
//
//            }
//            .frame(maxWidth: .infinity)
//            .clipped()
//            .background(Color(UIColor.systemBackground))
//            .cornerRadius(12)
//            .shadow(radius: 4)
//        }
//        .padding()
//    }
//}
//
//
//
//struct KeyboardAdaptive: ViewModifier {
//    @State private var keyboardHeight: CGFloat = 0
//    private var keyboardPublisher: AnyPublisher<CGFloat, Never> {
//        Publishers.Merge(
//            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
//                .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
//                .map { $0.height },
//            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
//                .map { _ in CGFloat(0) }
//        ).eraseToAnyPublisher()
//    }
//
//    func body(content: Content) -> some View {
//        content
//            .padding(.bottom, keyboardHeight)
//            .onReceive(keyboardPublisher) { self.keyboardHeight = $0 }
//            .animation(.easeOut(duration: 0.25), value: keyboardHeight)
//    }
//}
//
//extension View {
//    func keyboardAdaptive() -> some View {
//        self.modifier(KeyboardAdaptive())
//    }
//}
//// MARK: - Subviews
//extension DictionaryView {
//        
//
//    @ViewBuilder
//  
//    
//    private var alphabetSidebar: some View {
//        let letters: [String] = (97...122).compactMap { String(UnicodeScalar($0)) }
//        
//        return VStack(spacing: 0) {
//            ForEach(letters, id: \.self) { letter in
//                AlphabetLetterView(
//                    letter: letter,
//                    isActive: viewModel.isLetterActive(letter),
//                    isDragging: viewModel.dragActiveLetter == letter
//                )
//            }
//        }
//        .gesture(
//            DragGesture(minimumDistance: 0)
//                .onChanged { gesture in
//                    let y = gesture.location.y
//                    let index = Int((y / 18).rounded(.down))
//                    if (0..<letters.count).contains(index) {
//                        viewModel.handleLetterDrag(letters[index])
//                    }
//                }
//                .onEnded { _ in
//                    viewModel.handleLetterDragEnd()
//                }
//        )
//        .padding(.trailing, 6)
//    }
//    
//    private struct AlphabetLetterView: View {
//        let letter: String
//        let isActive: Bool
//        let isDragging: Bool
//        
//        var body: some View {
//            Text(letter.uppercased())
//                .font(.system(size: 11, design: .serif))
//                .foregroundColor(isActive ? AppColor.Button.Text.primary : AppColor.Text.secondary)
//                .frame(width: 20, height: 18)
//                .background(
//                    Circle().fill(isActive ? AppColor.Text.primary : .clear)
//                )
//                .scaleEffect(isDragging ? 2.0 : 1.0)
//                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isDragging)
//        }
//    }
//    
//    private var searchBar: some View {
//        HStack(spacing: 8) {
//            Image(systemName: "magnifyingglass")
//                .frame(width: 17)
//                .foregroundColor(.gray)
//            
//            TextField("Search", text: $viewModel.searchText)
//                .autocapitalization(.none)
//                .padding(.vertical, 8)
//                .font(.caption)
//                .frame(height: 22)
//                .frame(maxWidth: .infinity)
//                .foregroundColor(.gray)
//        }
//        .padding(.horizontal, 14)
//        .padding(.vertical, 8)
//        .background(Color.gray.opacity(0.32))
//        .cornerRadius(100)
//        .padding(.horizontal)
//        .padding(.bottom, 8)
//    }
//    var activeLetter: String {
//        guard viewModel.selectedIndex < viewModel.filteredSlangs.count else { return "" }
//        return String(viewModel.filteredSlangs[viewModel.selectedIndex].slang.prefix(1).uppercased())
//       }
//}
//
// 
//
//
//#Preview {
//    DictionaryView()
//        .environment(PopupManager())
//}
