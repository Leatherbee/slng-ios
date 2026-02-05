//
//  FloatingSearchBar.swift
//  SlangTranslator
//
//  A floating search bar component with iOS 26 Liquid Glass effect.
//  Positioned at the bottom of the screen, above the tab bar.
//

import SwiftUI

struct FloatingSearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    var placeholder: String = "Type a slang you don't know"
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        if #available(iOS 26.0, *) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .focused($isFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        onSubmit?()
                    }
                
                if !text.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            text = ""
                        }
                        Haptics.selection()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.primary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassEffect(.regular.interactive(), in: .capsule)
            .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
        } else {
            // Fallback on earlier versions
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .focused($isFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        onSubmit?()
                    }
                
                if !text.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            text = ""
                        }
                        Haptics.selection()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.primary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
        }
    }
}

// MARK: - Keyboard-aware container

struct KeyboardAwareFloatingSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Type a slang you don't know"
    var bottomPadding: CGFloat = 60

    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        VStack {
            Spacer()

            FloatingSearchBar(text: $text, placeholder: placeholder)
                .padding(.horizontal, 16)
                .padding(.bottom, keyboardHeight > 0 ? keyboardHeight - 30 : bottomPadding)
        }
        .ignoresSafeArea(.keyboard)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        KeyboardAwareFloatingSearchBar(text: .constant(""))
    }
}
