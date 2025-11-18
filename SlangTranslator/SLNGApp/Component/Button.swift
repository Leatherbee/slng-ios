//
//  Button.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 18/11/25.
//
import SwiftUI
 
struct PrimaryButton<Label: View>: View {
    let buttonColor: Color
    let textColor: Color
    let action: () -> Void
    @ViewBuilder let label: () -> Label
 
    var accessibilityLabelOverride: String?
    var accessibilityHintOverride: String?

    @State private var isPressed: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        buttonColor: Color,
        textColor: Color,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.buttonColor = buttonColor
        self.textColor = textColor
        self.action = action
        self.label = label
        self.accessibilityLabelOverride = accessibilityLabel
        self.accessibilityHintOverride = accessibilityHint
    }

    var body: some View {
        Button {
            Haptics.primaryButtonTap()
            action()
        } label: {
            label()
                .foregroundColor(textColor) 
                .background(buttonColor)
                .clipShape(Capsule())
                .scaleEffect(isPressed ? 1.05 : 1.0)
                .contentShape(Capsule())
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(accessibilityLabelOverride ?? "")  
        .accessibilityHint(accessibilityHintOverride ?? "Activates primary action")
        .accessibilityRepresentation {
            if let custom = accessibilityLabelOverride {
                Text(custom)
            } else {
                label()
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isPressed else { return }
                    withAnimation(reduceMotion ?
                                  .default :
                                  .spring(response: 0.2, dampingFraction: 0.5)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(reduceMotion ?
                                  .default :
                                  .spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }
}



#Preview {
    VStack{
        PrimaryButton(buttonColor: AppColor.Button.primary, textColor: AppColor.Button.Text.primary){
            
        } label : {
            Text("Button Primary")
        }
    }
    .padding(.horizontal, 80)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.Background.primary)
  

}
