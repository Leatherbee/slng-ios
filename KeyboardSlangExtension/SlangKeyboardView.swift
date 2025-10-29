//
//  SlangKeyboardView.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 22/10/25.
//

import SwiftUI
import SwiftData

struct SlangKeyboardView: View {
    var insertText: (String) -> Void
    var deleteText: () -> Void
    
    let keyboardHeight: CGFloat
    var backgroundColor: Color
    var needsInputModeSwitchKey: Bool = false
    var nextKeyboardAction: Selector? = nil
    
    @ObservedObject var vm: SlangKeyboardViewModel
    
    var body: some View {
        if vm.mode == .normal {
            keyboardView(vm: vm)
        } else if vm.mode == .explain {
            VStack(alignment: .leading, spacing: 8) {
                // Leading keyboard button
                Button {
                    vm.changeDisplayMode(.normal)
                } label: {
                    Image(systemName: "keyboard")
                        .foregroundStyle(.gray)
                        .font(.system(size: 17))
                        .frame(width: 34, height: 34)
                        .background(.white)
                        .clipShape(Circle())
                        .shadow(radius: 0.5)
                }
                .padding(.leading, 12)
                .padding(.top, 4)

                // Scrollable explanation content
                ZStack {
                    ScrollView {
                        explainView(vm: vm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                    }

                    // Loading overlay
                    if vm.isTranslating {
                        VStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                .scaleEffect(1.2)

                            Text("Translating...")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(20)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(radius: 2)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: vm.isTranslating)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func explainView(vm: SlangKeyboardViewModel) -> some View {
        VStack(alignment: .leading ,spacing: 4) {
            
            
            Text(vm.getClipboardText())
                .font(.system(.title, design: .serif, weight: .bold))
                .lineLimit(4)
                .minimumScaleFactor(0.6)
                .allowsTightening(true)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .foregroundStyle(.gray)
                .padding(.horizontal, 6)
                .padding(.vertical)
            
            Text(vm.translatedText)
                .font(.system(.title, design: .serif, weight: .bold))
                .foregroundStyle(.secondary)
                .lineLimit(4)
                .minimumScaleFactor(0.6)
                .allowsTightening(true)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Slang detected (\(vm.detectedSlangs.count))")
                .foregroundColor(.black)
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)
                .padding(.vertical, 14)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(vm.detectedSlangs, id: \.id) { slang in
                    KeyboardSlangCardView(slangData: slang)
                    Divider()
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 12)
            
            Spacer()
        }
        .background(backgroundColor)
    }
    
    private func keyboardView(vm: SlangKeyboardViewModel) -> some View {
        VStack(spacing: 6) { // tighter, more Apple-like vertical spacing
            HStack(spacing: 8) {
                Button {
                    Task {
                        vm.isTranslating = true
                        await vm.translateFromClipboard()
                        vm.changeDisplayMode(.explain)
                    }
                } label: {
                    Image(systemName: "document.on.document")
                        .foregroundStyle(.gray)
                        .font(.system(size: 17))
                        .frame(width: 34, height: 34)
                        .background(.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 0.5, y: 0.5)
                }

                
                Text("Copy that slang, paste it here")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            // MARK: - Key Rows
            ForEach(0..<vm.getRows().count, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    if rowIndex == 2 {
                        let label = vm.showNumbersShifted ? "123"
                        : vm.showNumber ? "#+="
                        : "⇧"
                        
                        keyButton(label: label, width: 44, fontsize: vm.showNumber ? 14 : 22) {
                            withAnimation(.none) {
                                if vm.showNumbersShifted {
                                    vm.showNumbersShifted.toggle()
                                } else if vm.showNumber {
                                    vm.showNumbersShifted.toggle()
                                } else {
                                    vm.toggleShift()
                                }
                            }
                        }
                    }
                    
                    ForEach(vm.getRows()[rowIndex], id: \.self) { key in
                        keyButton(
                            label: displayLabel(for: key),
                            width: rowIndex == 2 && vm.showNumber ? 46 : nil
                        ) {
                            insertText(displayLabel(for: key))
                            if vm.isShifted && !vm.showNumber {
                                vm.isShifted = false
                            }
                        }
                    }
                    
                    if rowIndex == 2 {
                        keyButton(systemName: "delete.left", width: 44) {
                            deleteText()
                        }
                    }
                }
                .padding(.horizontal, rowIndex == 1 ? 14 : 6) // mimic Apple row staggering
            }

            // MARK: - Bottom Function Row
            HStack(spacing: 6) {
                if needsInputModeSwitchKey, let nextKeyboardAction {
                    NextKeyboardButtonOverlay(action: nextKeyboardAction)
                        .frame(width: 40, height: 44)
                        .background(keyColor)
                        .cornerRadius(6)
                }
                
                keyButton(label: vm.showNumber ? "ABC" : "123", width: 48) {
                    withAnimation(.none) {
                        if vm.showNumber {
                            vm.showNumber.toggle()
                            vm.showNumbersShifted = false
                        } else {
                            vm.showNumber.toggle()
                        }
                    }
                }
                
                keyButton(systemName: "face.smiling", width: 48) { }
                
                keyButton(label: "space", width: 150, fontsize: 17) { insertText(" ") }
                
                keyButton(label: "return", width: 76, fontsize: 17) { insertText("\n") }
            }
            .padding(.horizontal, 6)
        }
        .padding(.vertical, 8)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .frame(height: keyboardHeight)
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private func keyButton(
        label: String? = nil,
        systemName: String? = nil,
        width: CGFloat? = nil,
        fontsize: CGFloat = 22,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(keyColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(keyBorder, lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
                
                if let label = label {
                    Text(label)
                        .font(.system(size: fontsize))
                        .foregroundColor(.primary)
                    
                } else if let systemName = systemName {
                    Image(systemName: systemName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(width: width ?? 32, height: 44)
        }
        .buttonStyle(.plain)
    }
    
    private func displayLabel(for key: String) -> String {
        vm.isShifted ? key.uppercased() : key.lowercased()
    }
    
    private var keyColor: Color {
        Color(.white.opacity(0.85))
    }
    
    private var keyBorder: Color {
        Color.black.opacity(0.00)
    }
    
    struct NextKeyboardButtonOverlay: UIViewRepresentable {
        let action: Selector
        func makeUIView(context: Context) -> UIButton {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "globe"), for: .normal)
            button.tintColor = .label
            button.addTarget(nil, action: action, for: .allTouchEvents)
            return button
        }
        func updateUIView(_ uiView: UIButton, context: Context) {}
    }
}
//
//#Preview("Keyboard Preview (App Context)") {
//    SlangKeyboardView(
//        insertText: { print("inserted:", $0) },
//        deleteText: { print("deleted") },
//        keyboardHeight: 260,
//        backgroundColor: Color(UIColor.systemGray6),
//        needsInputModeSwitchKey: true,
//        nextKeyboardAction: nil,
//        vm:
//    )
//    .previewLayout(.fixed(width: 390, height: 280))
//    .padding()
//}
