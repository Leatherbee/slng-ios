import SwiftUI
internal import Combine

struct TranslateLoadingSection: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @AppStorage("reduceMotionEnabled", store: UserDefaults.shared) private var reduceMotionEnabled: Bool = false
    @Bindable var viewModel: TranslateViewModel
    var textNamespace: Namespace.ID
    var dynamicTextStyle: Font.TextStyle

    @State private var currentMessage: String = ""
    @State private var dotCount: Int = 0
    @State private var timer: Timer?

    private let loadingMessages = [
        "Decoding what your slang really means",
        "Analyzing tone, context, and chaos",
        "Catching the real vibe behind your words",
        "Checking emotional damage levels",
        "Consulting the slang gods",
        "Making sense of this linguistic rollercoaster",
        "Translating chaos into meaning",
        "Detecting hidden sarcasm layers",
        "Running a full vibe analysis",
        "Reconstructing your emotional sentence structure",
        "Dissecting the energy behind that slang",
        "Searching the archives of Gen Z dictionary",
        "Cross-checking with Jakarta street linguistics",
        "Comparing with online war archives",
        
        "Still processing your linguistic masterpiece",
        "Wait—was that supposed to be friendly?",
        "Our translator just went 😵‍💫",
        "Slang so strong, even our AI is sweating",
        "Loading context… like your friend’s late reply",
        "Consulting urban dictionary and praying",
        "Running a vibe check on your sentence",
        "Checking how offended we should be",
        "The slang AI needs a breather",
        "Hold tight, decoding your chaos in 4K",
        "Making sure it’s not just capslock rage",
        
        "Rebooting brain cells...",
        "Polishing your words till they shine",
        "Verifying if that’s sarcasm or trauma",
        "Syncing with millennial emotions",
        "Assembling emotional context packets",
        "Extracting hidden meaning behind emojis",
        "Asking linguists for a second opinion",
        "Debugging cultural nuances",
        "Performing semantic autopsy",
        
        "Untangling your sentence spaghetti",
        "Almost got it",
        "Hold my bahasa",
        "Decoding on vibes only",
        "Finding meaning in the chaos",
        "Loading the dictionary of emotions",
        "Reconstructing what you *really* meant",
        "Translating the untranslatable",
        "Updating slang database v2.0",
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
        
        if !(reduceMotion || reduceMotionEnabled) {
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
