//
//  TranslateView.swift
//  IndoSlangTrans
//
//  Created by Cynthia Yapiter on 20/10/25.
//
import SwiftUI

struct TranslateView: View {
    @State private var inputText: String = ""
    @State private var dynamicTextStyle: Font.TextStyle = .largeTitle  // largeTitle default
    
    @State private var textHeight: CGFloat = 100 // initial height
    
    var body: some View {
        GeometryReader { geometry in
            VStack(){
                Spacer()
                ZStack(alignment: .leading) {
                    if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Heard a slang you don't get? Type here")
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .zIndex(1)
                    }
                    
                    TextEditor(text: $inputText)
                        .font(.system(dynamicTextStyle, design: .serif, weight: .bold))
                        .frame(height: textHeight)
                        .onChange(of: inputText) {
                            adjustFontSize()
                            recalcHeight(geometry: geometry)
                        }
                        .padding(.horizontal)
                        .zIndex(0)
                }
                .font(.system(.largeTitle, design: .serif, weight: .bold))
                .padding()
                .simultaneousGesture(
                    TapGesture().onEnded {
                        UIApplication.shared.dismissKeyboard()
                    }
                )
                .gesture(
                    DragGesture().onChanged { _ in
                        UIApplication.shared.dismissKeyboard()
                    }
                )
                .frame(maxWidth: .infinity)
//                .position(x: geometry.size.width / 2,
//                          y: geometry.size.height / 2)
                
                Spacer()
                
            }
            .frame(maxWidth: .infinity, maxHeight: geometry.size.height)
            .onAppear {
                recalcHeight(geometry: geometry)
            }
            
        }
        
        Button{
            print("Added to Keyboard")
        } label: {
            Text("Translate  →")
                .padding(.vertical, 18)
                .font(Font.body.bold())
                .foregroundColor(Color(.white))
        }
        .frame(maxWidth: 314, minHeight: 60)
        .background(Color(.black))
        .clipShape(RoundedRectangle(cornerRadius: 30))
        
    }
        
    private func adjustFontSize() {
        let length = inputText.count
        // simple heuristic for dynamic font scaling
        withAnimation(.easeInOut(duration: 0.2)) {
            switch length {
            case 0...40: dynamicTextStyle = .largeTitle
            case 41...100: dynamicTextStyle = .title
            case 101...200: dynamicTextStyle = .title2
            case 201...340: dynamicTextStyle = .title3
            default: dynamicTextStyle = .headline
            }
        }
    }
    
    private func recalcHeight(geometry: GeometryProxy) {
        // Measure text height dynamically
        let width = geometry.size.width - 32
        let estimatedHeight = inputText.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.preferredFont(forTextStyle: .largeTitle)],
            context: nil
        ).height + 50
        
        // Limit growth so it doesn’t exceed screen height
        textHeight = min(estimatedHeight, geometry.size.height - 30)
    }
}

#Preview {
    TranslateView()
}


extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
