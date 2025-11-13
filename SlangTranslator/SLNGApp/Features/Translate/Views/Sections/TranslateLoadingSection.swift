import SwiftUI
internal import Combine

struct TranslateLoadingSection: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @ObservedObject var viewModel: TranslateViewModel
    var textNamespace: Namespace.ID
    var dynamicTextStyle: Font.TextStyle

    @State private var currentMessage: String = ""
    @State private var dotCount: Int = 0
    @State private var timer: Timer?

    private let loadingMessages = [
        "Decoding...",
        "Sensing the vibe behind your words",
        "Checking the damage level",
        "Consulting the slang gods",
        "Making this make sense",
        "Translating this chaos",
        "Running analysis, not rotting with the unknown",
        "Dissecting the energy behind that slang",
        "Searching for meaning, not just empty words",
        
        "Still processing your masterpiece",
        "Wait—was that supposed to be friendly?",
        "Our translator just went 😵‍💫",
        "Slang so strong, even you are waiting",
        "Loading context… like your friend’s late reply",
        "Consulting urban dictionary and praying",
        "Checking how offended we should be",
        "Hold tight, decoding your chaos in 4K",
        
        "Hold on, we’re almost there!",
        "Rebooting brain cells...",
        "Vibes check in process...",
        "Asking who for a second opinion?",
        "Our AI definitely didn't ask to resign",
        
        "That sentence might need a tarot reading ses",
        "Brewing the translation potion",
        "Almost got it",
        "Hold my bahasa",
        "Getting real close... like your situasionship",
        "Decoding on vibes only",
        "Reconstructing what you *really* meant",
        "Understanding your needs better than your ex",
    ]
    
    private let recordingMessages = [
        "Recording...",
        "Load your chaos in mp3",
        "Listening patiently",
        
        "You're done talking? Re-tap the button :)",
        "Yap enough? Re-tap the button :)",
        "I'm getting impatient",
        "Can't wait to rest",
        "I'm just a machine, have mercy and end it",
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            
            Text("\(currentMessage)\(String(repeating: ".", count: dotCount))")
                .font(.system(dynamicTextStyle, design: .serif, weight: .bold))
                .foregroundColor(.secondary)
                .matchedGeometryEffect(
                    id: "originalText",
                    in: textNamespace,
                    properties: .position,
                    anchor: .topLeading,
                    isSource: false
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 100, maxHeight: 300, alignment: .topLeading)
                .padding(.horizontal, 5)
                .padding(.top, 8)
                .multilineTextAlignment(.leading)
                .scaleEffect(1.02)
                .animation(.interpolatingSpring(stiffness: 180, damping: 12), value: currentMessage)
                .animation(.interpolatingSpring(stiffness: 150, damping: 14), value: dotCount)
            
            Spacer()
            
            Color.clear
                .frame(height: 60)
                .padding(.bottom)
        }
        .padding()
        .onAppear {
            startLoopingAnimation()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .toolbar(.hidden, for: .tabBar)
    }
    
    private func startLoopingAnimation() {
        var availableMessages = loadingMessages.shuffled()
        currentMessage = availableMessages.popLast() ?? "Loading..."
        
        var tickCounter = 0
        
        if !reduceMotion {
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                withAnimation(.interpolatingSpring(stiffness: 150, damping: 14)) {
                    dotCount = (dotCount + 1) % 4
                }
                tickCounter += 1
                
                let randomThreshold = Int.random(in: 3...5)
                if tickCounter >= randomThreshold {
                    tickCounter = 0
                    
                    if availableMessages.isEmpty {
                        availableMessages = loadingMessages.shuffled()
                    }
                    withAnimation(.interpolatingSpring(stiffness: 180, damping: 12)) {
                        currentMessage = availableMessages.popLast() ?? currentMessage
                    }
                }
            }
        } else {
            currentMessage = "\(availableMessages.popLast() ?? "Loading")..."
        }
    }
}
