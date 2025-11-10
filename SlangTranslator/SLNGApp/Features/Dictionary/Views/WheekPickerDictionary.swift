//
//  DictionaryTrash.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 07/11/25.
//
 
import SwiftUI
import CoreHaptics
import SwiftData

struct DictionaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PopupManager.self) private var popupManager
    @State private var selected = 2
    @StateObject private var viewModel = WheelPickerDictionaryViewModel()
    @State private var scrollToIndexTrigger: Int? = nil

    
    var body: some View {
        VStack(spacing: 24) {
            HStack{
                SwiftUIWheelPicker(items: viewModel.data.map { $0.slang}, selection: $selected, scrollToIndexTrigger: $scrollToIndexTrigger) { item, idx, isSelected in
                    let distance = abs(selected - idx)
                    let (fontSize, rowHeight, opacity): (CGFloat, CGFloat, Double)
                    switch distance {
                    case 0: (fontSize, rowHeight, opacity) = (64, 76, 1.0)
                    case 1: (fontSize, rowHeight, opacity) = (48, 57, 0.8)
                    case 2: (fontSize, rowHeight, opacity) = (40, 48, 0.6)
                    case 3: (fontSize, rowHeight, opacity) = (34, 41, 0.4)
                    case 4: (fontSize, rowHeight, opacity) = (28, 33, 0.2)
                    default: (fontSize, rowHeight, opacity) = (28, 33, 0.0)
                    }
                    
                    return AnyView(
                        HStack(spacing: 32) {
                            Text(item)
                                .font(.system(size: fontSize, weight: isSelected ? .bold : .medium, design: .serif))
                                .frame(height: rowHeight)
                                .padding(.leading, 8)
                                .opacity(opacity)
                                .scaleEffect(isSelected ? 1.1 : 1.0)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .animation(.easeInOut(duration: 0.1324), value: selected)
                                .layoutPriority(1)
                            
                            if isSelected {
                                Image(systemName: "arrow.right")
                                    .resizable()
                                    .frame(width: 48, height: 24)
                                    .foregroundColor(.primary)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
                            }
                        }
                            .frame(maxWidth: .infinity, alignment: .center)
                    )
                }
                .frame(height: 573)
                .frame(maxWidth: .infinity)
                .clipped()
                .background(Color(UIColor.systemBackground))
                
                alphabetSidebar
            }
           
            searchBar
            
        }
        .padding()
        .task {
            viewModel.setContext(context: modelContext)
            viewModel.loadData()
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
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.32))
        .cornerRadius(100)
    }
    
    private var alphabetSidebar: some View {
        let letters: [String] = (97...122).compactMap { String(UnicodeScalar($0)) }

        return VStack(spacing: 0) {
            ForEach(letters, id: \.self) { letter in
                AlphabetLetterView(
                    letter: letter,
                    isActive: viewModel.activeLetter == letter,
                    isDragging: viewModel.isDraggingLetter
                )
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    let y = gesture.location.y
                    let index = Int((y / 18).rounded(.down))
                    if (0..<letters.count).contains(index) {
                        let letter = letters[index]
                        viewModel.handleLetterDrag(letter)
                        
                        if let jumpIndex = viewModel.indexForLetter(letter) {
                            scrollToIndexTrigger = jumpIndex
                        }
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
}

public struct SwiftUIWheelPicker<Item, RowView>: View where RowView: View {
    private let items: [Item]
    @Binding private var selection: Int
    private let content: (Item, Int, Bool) -> RowView
    
    @Binding var scrollToIndexTrigger: Int?
    
    @State private var centers: [Int: CGFloat] = [:]
    @State private var heights: [Int: CGFloat] = [:]
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var dragging = false
    @State private var engine: UIImpactFeedbackGenerator? = nil
    
    // OPTIMASI: Cache untuk visible range
    @State private var visibleRange: Range<Int> = 0..<10
    
    public init(
        items: [Item],
        selection: Binding<Int>,
        scrollToIndexTrigger: Binding<Int?> = .constant(nil),
        @ViewBuilder content: @escaping (Item, Int, Bool) -> RowView
    ) {
        self.items = items
        self._selection = selection
        self._scrollToIndexTrigger = scrollToIndexTrigger
        self.content = content
    }
    
    public var body: some View {
        GeometryReader { outerGeo in
            let containerCenterY = outerGeo.frame(in: .global).midY
            
            ZStack {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 24) {
                            Color.clear.frame(height: outerGeo.size.height / 2)
                            ForEach(items.indices, id: \.self) { idx in
                                itemRow(for: idx)
                                    .background(
                                        GeometryReader { geo in
                                              let frame = geo.frame(in: .global)
                                              Color.clear
                                                  .preference(
                                                      key: RowCenterKey.self,
                                                      value: [RowCenter(id: idx, midY: frame.midY)]
                                                  )
                                                  .onAppear {
                                                      // OPTIMASI: Hanya simpan height jika belum ada
                                                      if heights[idx] == nil {
                                                          heights[idx] = frame.height
                                                      }
                                                      // OPTIMASI: Update visible range
                                                      updateVisibleRange(around: idx)
                                                  }
                                          }
                                    )
                            }
                            Color.clear.frame(height: outerGeo.size.height / 2)
                        }
                    }
                    .onAppear {
                        scrollProxy = proxy
                        engine = UIImpactFeedbackGenerator(style: .light)
                        engine?.prepare() // OPTIMASI: Prepare engine di awal
                        DispatchQueue.main.async {
                            proxy.scrollTo(selection, anchor: .center)
                        }
                    }
                    .onPreferenceChange(RowCenterKey.self) { values in
                        // OPTIMASI: Batasi update hanya untuk visible items
                        let filteredValues = values.filter { visibleRange.contains($0.id) }
                        if !filteredValues.isEmpty {
                            DispatchQueue.main.async {
                                for v in filteredValues { centers[v.id] = v.midY }
                                if !dragging {
                                    updateSelection(containerCenterY: containerCenterY, shouldFeedback: false)
                                }
                            }
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 1, coordinateSpace: .global)
                            .onChanged { _ in dragging = true }
                            .onEnded { _ in
                                dragging = false
                                snapToNearest(containerCenterY: containerCenterY)
                            }
                    )
                }
            }
        }
        .onChange(of: scrollToIndexTrigger) {
            guard let index = scrollToIndexTrigger else { return }
            // OPTIMASI: Langsung scroll tanpa delay
            scrollToIndex(index, animated: true)
            scrollToIndexTrigger = nil
        }
    }
    
    // OPTIMASI: Update visible range untuk lazy loading
    private func updateVisibleRange(around index: Int) {
        let buffer = 20 // Load 20 items di atas dan di bawah
        let start = max(0, index - buffer)
        let end = min(items.count, index + buffer)
        visibleRange = start..<end
    }
    
    @ViewBuilder
    private func itemRow(for idx: Int) -> some View {
        let isSelected = idx == selection
        content(items[idx], idx, isSelected)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                updateSelection(to: idx, animated: true)
            }
    }
    
    private func updateSelection(containerCenterY: CGFloat, shouldFeedback: Bool) {
        guard !centers.isEmpty else { return }
        // OPTIMASI: Hanya cek items dalam visible range
        let visibleCenters = centers.filter { visibleRange.contains($0.key) }
        if let nearest = visibleCenters.min(by: { abs($0.value - containerCenterY) < abs($1.value - containerCenterY) })?.key,
           nearest != selection {
            selection = nearest
            if shouldFeedback {
                engine?.impactOccurred()
            }
        }
    }
    
    private func snapToNearest(containerCenterY: CGFloat) {
        let visibleCenters = centers.filter { visibleRange.contains($0.key) }
        guard let nearest = visibleCenters.min(by: { abs($0.value - containerCenterY) < abs($1.value - containerCenterY) })?.key else { return }
        updateSelection(to: nearest, animated: true)
    }
    
    private func updateSelection(to newIndex: Int, animated: Bool) {
        guard newIndex >= 0 && newIndex < items.count else { return }
        selection = newIndex
        updateVisibleRange(around: newIndex)
        if let proxy = scrollProxy {
            withAnimation(animated ? .easeOut(duration: 0.25) : .none) {
                proxy.scrollTo(newIndex, anchor: .center)
            }
            engine?.impactOccurred()
        }
    }
    
    public func scrollToIndex(_ index: Int, animated: Bool = true) {
        guard index >= 0 && index < items.count else { return }
        selection = index
        updateVisibleRange(around: index)
        if let proxy = scrollProxy {
            // OPTIMASI: Gunakan animasi lebih cepat untuk jump jauh
            let distance = abs(index - selection)
            let duration = distance > 100 ? 0.15 : 0.25
            withAnimation(animated ? .easeOut(duration: duration) : .none) {
                proxy.scrollTo(index, anchor: .center)
            }
            engine?.impactOccurred()
        }
    }
}

private struct RowCenter: Equatable { let id: Int; let midY: CGFloat }
private struct RowCenterKey: PreferenceKey {
    static var defaultValue: [RowCenter] = []
    static func reduce(value: inout [RowCenter], nextValue: () -> [RowCenter]) {
        value.append(contentsOf: nextValue())
    }
}





#Preview{
    DictionaryView()
        .environment(PopupManager())
}
