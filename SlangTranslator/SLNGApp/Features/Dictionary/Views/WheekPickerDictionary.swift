//
//  DictionaryTrash.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 07/11/25.
//

// SwiftUIWheelPicker.swift
// Pure SwiftUI wheel picker (snapping, haptic, accessibility)
// Works with any array of values and a SwiftUI row builder.

import SwiftUI
import CoreHaptics

/// A pure-SwiftUI wheel picker.
/// - items: array of items
/// - selection: binding to selected index
/// - rowHeight: height for each row (important for snapping)
/// - content: view builder for each item

struct DemoWheelPickerView: View {
    @State private var selected = 2
    let fruits = [
           "Gabut", "Gaptek", "Garing", "Gebetan", "Gokil", "Gebetan", "Gas",
           "Gaje", "GWS", "Cucumber", "Date", "Dragon Fruit", "Durian", "Fig",
           "Gooseberry", "Grape", "Grapefruit", "Guava", "Honeydew", "Jackfruit",
           "Kiwi", "Lemon", "Lime", "Lychee", "Mango", "Melon", "Orange", "Papaya",
           "Peach", "Pear", "Pineapple", "Plum", "Pomegranate", "Raspberry",
           "Strawberry", "Tamarind", "Watermelon"
       ]

    var body: some View {
        VStack(spacing: 24) {
            SwiftUIWheelPicker(items: fruits, selection: $selected) { item, idx, isSelected in
                let distance = abs(selected - idx)

                // Tentukan font size & height berdasarkan jarak dari item terpilih
                let (fontSize, rowHeight, opacity): (CGFloat, CGFloat, Double)
                switch distance {
                case 0:
                    (fontSize, rowHeight, opacity) = (64, 76, 1.0)
                case 1:
                    (fontSize, rowHeight, opacity) = (48, 57, 0.8)
                case 2:
                    (fontSize, rowHeight, opacity) = (40, 48, 0.6)
                case 3:
                    (fontSize, rowHeight, opacity) = (34, 41, 0.4)
                case 4:
                    (fontSize, rowHeight, opacity) = (28, 33, 0.2)
                default:
                    (fontSize, rowHeight, opacity) = (28, 33, 0.0) // di luar jangkauan, bisa juga disembunyikan
                }

                return AnyView(
                    HStack(spacing: 32) {
                        // Tambahkan leading padding agar huruf pertama tidak terpotong saat animasi
                        Text(item)
                            .font(.system(size: fontSize, weight: isSelected ? .bold : .medium, design: .serif))
                            .frame(height: rowHeight)
                            .padding(.leading, 8) // ✅ ruang aman kiri
                            .opacity(opacity)
                            .scaleEffect(isSelected ? 1.1 : 1.0)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .animation(.easeInOut(duration: 0.25), value: selected)
                            .layoutPriority(1) // ✅ pastikan teks prioritasnya lebih tinggi dari arrow

                        // Placeholder agar layout stabil (tidak bergeser)
                        if isSelected {
                            Image("arrowHome")
                                .resizable()
                                .frame(width: 64, height: 18)
                                .tint(AppColor.Text.primary)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .opacity
                                ))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                        .frame(maxWidth: .infinity)
                )
            }
            .frame(maxWidth: .infinity)
            .clipped()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 4)
        }
        .padding()
    }

}

public struct SwiftUIWheelPicker<Item, RowView>: View where RowView: View {
    private let items: [Item]
    @Binding private var selection: Int
    private let content: (Item, Int, Bool) -> RowView

    @State private var centers: [Int: CGFloat] = [:]
    @State private var heights: [Int: CGFloat] = [:]
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var dragging = false
    @State private var engine: UIImpactFeedbackGenerator? = nil

    public init(
        items: [Item],
        selection: Binding<Int>,
        @ViewBuilder content: @escaping (Item, Int, Bool) -> RowView
    ) {
        self.items = items
        self._selection = selection
        self.content = content
    }

    public var body: some View {
        GeometryReader { outerGeo in
            let containerCenterY = outerGeo.frame(in: .global).midY

            ZStack {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
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
                                                    heights[idx] = frame.height
                                                }
                                                .onChange(of: frame.height) { new in
                                                    heights[idx] = new
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
                        DispatchQueue.main.async {
                            proxy.scrollTo(selection, anchor: .center)
                        }
                    }
                    .onPreferenceChange(RowCenterKey.self) { values in
                        for v in values { centers[v.id] = v.midY }
                        if !dragging {
                            updateSelection(containerCenterY: containerCenterY, shouldFeedback: false)
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
        if let nearest = centers.min(by: { abs($0.value - containerCenterY) < abs($1.value - containerCenterY) })?.key,
           nearest != selection {
            selection = nearest
            if shouldFeedback { engine?.impactOccurred() }
        }
    }

    private func snapToNearest(containerCenterY: CGFloat) {
        guard let nearest = centers.min(by: { abs($0.value - containerCenterY) < abs($1.value - containerCenterY) })?.key else { return }
        updateSelection(to: nearest, animated: true)
    }

    private func updateSelection(to newIndex: Int, animated: Bool) {
        guard newIndex >= 0 && newIndex < items.count else { return }
        selection = newIndex
        if let proxy = scrollProxy {
            withAnimation(animated ? .easeOut(duration: 0.25) : .none) {
                proxy.scrollTo(newIndex, anchor: .center)
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
    DemoWheelPickerView()
}

