//
//  SlangKeyboardView.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 22/10/25.
//

import SwiftUI
 
struct SlangKeyboardView: View {
    var insertText: (String) -> Void
    var deleteText: () -> Void
    
    let keyboardHeight: CGFloat
    var backgroundColor: Color
    var needsInputModeSwitchKey: Bool = false
    var nextKeyboardAction: Selector? = nil
     
    @StateObject private var vm = SlangKeyboardViewModel()
    
    var body: some View {
        if vm.mode == .normal {
            keyboardView
        } else if vm.mode == .explain {
            explainView
        }
    }
    
    private var explainView: some View {
        VStack(alignment: .leading ,spacing: 4) {
            HStack{
                Button {
                    vm.changeDisplayMode(.normal)
                } label: {
                    Image(systemName: "keyboard")
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                }
                .frame(width: 35, height: 35)
                .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                .cornerRadius(9999)
            }
            .padding(.leading, 12)
           

            Text("Slang detected (1)")
                .foregroundColor(.black)
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 12)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(vm.slangText)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .foregroundColor(.black.opacity(0.8))
                    Spacer()
                    Text(vm.translationEN)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                }
                
                Divider().background(Color.white.opacity(0.4))
                
                Label("Context", systemImage: "info.circle")
                    .foregroundColor(.black)
                    .font(.system(size: 14, weight: .medium))
                
                Text(vm.contextEn)
                    .foregroundColor(.black.opacity(0.9))
                    .font(.system(size: 13))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Example:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.black)
                    Text(vm.exampleID)
                        .italic()
                        .foregroundColor(.black)
                    Text(vm.exampleEN)
                        .italic()
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .padding()
            .background(.white)
            .cornerRadius(12)
            .padding(.horizontal, 8)
            
            Spacer()
        }
    }
    
    private var keyboardView: some View {
        VStack(spacing: 8) {
            
            HStack {
                HStack{
                    HStack{
                        Text("IS")
                            .foregroundColor(Color.white)
                            .font(.system(size: 10))
                    }
                    .frame(width: 21, height: 21)
                    .background(Color.gray)
                    .cornerRadius(9999)
                    Image(systemName: "arrow.right")
                        .foregroundColor(Color.gray)
                        .font(.system(size: 10))
                    HStack{
                        Text("EN")
                            .foregroundColor(.white)
                            .font(.system(size: 10))
                    }
                    .frame(width: 21, height: 21)
                    .background(Color(red: 0.5, green: 0.5, blue: 0.5))
                    .cornerRadius(9999)
                }
                Spacer()
                Text("Paste to translate to Indonesian Slang")
                    .foregroundColor(.white)
                    .font(Font.system(size: 12))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer()
                Button{
                    Task{
                        vm.translateFromClipboard()
                        vm.changeDisplayMode(.explain)
                    }
                    
                }label:{
                    Text("Explain")
                        .foregroundColor(.white)
                        .font(.system(size: 10))
                }
                .padding( 8.75)
                .background(Color(red: 0.5, green: 0.5, blue: 0.5))
                .cornerRadius(9999)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .cornerRadius(8)
            
            ForEach(0..<vm.getRows().count, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    if rowIndex == 2 {
                        // Tombol kiri bawah
                        let label = vm.showNumbersShifted ? "123"
                            : vm.showNumber ? "#+="
                            : "⇧"
                        
                        keyButton(label: label, width: 45, fontsize: vm.showNumber ? 14 : 22) {
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
                        keyButton(label: vm.isShifted ? key.uppercased() : key.lowercased(),
                                  width: rowIndex == 2 && vm.showNumber ? 50 : nil) {
                            insertText(vm.isShifted ? key.uppercased() : key.lowercased())
                            if vm.isShifted && !vm.showNumber {
                                vm.isShifted = false
                            }
                        }
                    }
                    
                    if rowIndex == 2 {
                        keyButton(systemName: "delete.left", width: 45) {
                            deleteText()
                        }
                    }
                }
                .padding(.horizontal, rowIndex == 1 ? 10 : 4)
            }

             
            HStack(spacing: 6) {
                if needsInputModeSwitchKey, let nextKeyboardAction {
                    NextKeyboardButtonOverlay(action: nextKeyboardAction)
                        .frame(width: 40, height: 44)
                        .background(keyColor)
                        .cornerRadius(6)
                }
                
                keyButton(label: vm.showNumber ? "ABC" : "123", width: 50) {
                    withAnimation(.none) {
                        if vm.showNumber {
                            vm.showNumber.toggle()
                            vm.showNumbersShifted = false
                        
                        } else {
                            vm.showNumber.toggle()
                        }
                    }
                  
                   
                }
                keyButton(systemName: "face.smiling", width: 50) { }
                keyButton(label: "    ", width: 120) { insertText(" ") }
                
                ZStack {
                    keyButton(systemName: "translate", width: 50) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 1.0)) {
                            vm.showTranslationPopup.toggle()
                        }
                    }
                    
                    if vm.showTranslationPopup {
                        VStack(spacing: 4) {
                            Text("Indonesia → English")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            Text(vm.translatedText)
                                .frame(maxWidth: .infinity)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.302, green: 0.302, blue: 0.302))
                                .cornerRadius(4)
                        }
                        .padding(6)
                        .background(Color(red: 0.588, green: 0.604, blue: 0.627))
                        .cornerRadius(8)
                        .frame(width: 120)
                        .offset(y: -50) // melayang di atas tombol
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(10) // tetap di atas semua
                    }
                }
                .frame(width: 50, height: 44)
                
                keyButton(label: "return", width: 70, fontsize: 18) { insertText("\n") }
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 10)
        .background(backgroundColor)
        .cornerRadius(10)
        .clipped(antialiased: false)
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
    
    // MARK: - Next Keyboard Button Overlay (system button)
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

#Preview("Keyboard Preview (App Context)") {
    SlangKeyboardView(
        insertText: { print("inserted:", $0) },
        deleteText: { print("deleted") },
        keyboardHeight: 260,
        backgroundColor: Color(UIColor.systemGray6),
        needsInputModeSwitchKey: true,
        nextKeyboardAction: nil
    )
    .previewLayout(.fixed(width: 390, height: 280))
    .padding()
}
