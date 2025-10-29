//
//  MainTabbedView.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 21/10/25.
//
import SwiftUI 

enum TabSelection: Hashable {
    case translate
    case keyboard
    case dictionary
}

struct MainTabbedView: View {
    @State private var selectedTab: TabSelection = .translate
    @State private var popupManager = PopupManager()
    @State private var reveal = false
    var body: some View{
        ZStack{
            TabView(selection: $selectedTab) {
                Tab("Translate", systemImage: "translate", value: .translate) {
                    TranslateView()
                }
                
                Tab("Keyboard", systemImage: "keyboard", value: .keyboard) {
                    KeyboardView()
                }
                
                Tab("Dictionary", systemImage: "text.book.closed", value: .dictionary) {
                    DictionaryView()
                        .environment(popupManager)
                }
                
            }
            .tint(.primary)
            if popupManager.isPresented {
                DictionaryDetail()
                    .environment(popupManager)
                    .zIndex(1)
                    .transition(.revealFromCenter)
            }
            
            
            
        }
        .animation(.spring(response: 0.175, dampingFraction: 1.0), value: popupManager.isPresented)
        
    }
    
}

// MARK: - Custom Transition
extension AnyTransition {
    static var revealFromCenter: AnyTransition {
        AnyTransition.modifier(
            active: ScaleAndClipModifier(scale: 0.0),
            identity: ScaleAndClipModifier(scale: 1.0)
        )
    }
}

// MARK: - Scale + Clip Modifier
struct ScaleAndClipModifier: ViewModifier {
    var scale: CGFloat
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
                content
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(y: scale, anchor: .center) // muncul dari tengah ke atas-bawah
                    .opacity(scale > 0 ? 1 : 0)
            }
    }
}

