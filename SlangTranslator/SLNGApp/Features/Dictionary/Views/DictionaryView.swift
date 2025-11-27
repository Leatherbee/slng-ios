//
//  DictionaryView.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 07/11/25.
//

import SwiftUI
import CoreHaptics
import SwiftData
import AVFoundation
internal import Combine
import FirebaseAnalytics

struct DictionaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PopupManager.self) private var popupManager
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Binding var searchText: String
    @State private var selected = 2
    @StateObject private var viewModel = DictionaryViewModel()
    @State private var scrollToIndexTrigger: Int? = nil
    private static let letters: [String] = (97...122).compactMap { String(UnicodeScalar($0)) }
    @State private var lastOverlayLetter: String = ""
    @State private var jumpAnimated: Bool = true
    @State private var lastJumpTime: CFTimeInterval = 0
    @AppStorage("soundEffectEnabled", store: UserDefaults.shared) private var soundEffectEnabled: Bool = true

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColor.Background.secondary
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    SwiftUIWheelPicker(
                        items: viewModel.filteredCanonicals.map { $0.canonical },
                        selection: $selected,
                        scrollToIndexTrigger: $scrollToIndexTrigger,
                        jumpAnimated: $jumpAnimated,
                        onSelectedTap: { index in
                            if viewModel.filteredCanonicals.indices.contains(index) {
                                let group = viewModel.filteredCanonicals[selected]
                                popupManager.setCanonicalForm(group.canonical)
                                popupManager.setVariants(group.variants)
                                Analytics.logEvent("dictionary_item_viewed", parameters: [
                                    "variants_count": group.variants.count
                                ])
                                popupManager.isPresented.toggle()
                            }
                        }
                    ) { (item: String, idx: Int, isSelected: Bool) in
                        let distance = abs(selected - idx)
                        let (fontSize, opacity, rowHeight): (CGFloat, Double, CGFloat)
                        switch distance {
                        case 0: (fontSize, opacity, rowHeight) = (60, 1.0, 76)
                        case 1: (fontSize, opacity, rowHeight) = (44, 0.8, 57)
                        case 2: (fontSize, opacity, rowHeight) = (30, 0.6, 58)
                        case 3: (fontSize, opacity, rowHeight) = (24, 0.4, 41)
                        case 4: (fontSize, opacity,rowHeight) = (20, 0.2, 33)
                        default: (fontSize, opacity, rowHeight) = (20, 0.0, 33)
                        }

                        return AnyView(
                            HStack(spacing: 28) {
                                Text(item)
                                    .font(.system(size: fontSize, weight: isSelected ? .bold : .medium, design: .serif))
                                    .padding(.leading, 8)
                                    .opacity(opacity)
                                    .scaleEffect(isSelected ? 1.1 : 1.0)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.4)
                                    .layoutPriority(1)

                                if isSelected {
                                    Image(systemName: "arrow.right")
                                        .resizable()
                                        .frame(width: 44, height: 24)
                                        .foregroundColor(.primary)
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
                                }
                            }
                            .frame(height: rowHeight)
                            .frame(maxWidth: .infinity, alignment: .center)
                        )
                    }
                    .frame(height: 620)
                    .frame(maxWidth: .infinity)
                    .clipped()

                    optimizedAlphabetSidebar
                }
            }
            .padding()
             
            VStack {
                let displayLetter: String = {
                    if let l = viewModel.activeLetter, !l.isEmpty { return l }
                    return lastOverlayLetter
                }()
                Text(displayLetter.uppercased())
                    .font(.system(size: 64, design: .serif))
                    .foregroundColor(AppColor.Text.secondary)
                    .allowsHitTesting(false)
            }
            .frame(width: 128, height: 128)
            .background(.clear)
            .clipShape(.circle)
            .allowsHitTesting(false)
        }
        .task {
            viewModel.setContext(context: modelContext)
            viewModel.loadData()
        }
        .onAppear {
            if let l = viewModel.activeLetter, !l.isEmpty {
                lastOverlayLetter = l
            } else if viewModel.filteredCanonicals.indices.contains(selected), let first = viewModel.filteredCanonicals[selected].canonical.first {
                lastOverlayLetter = String(first).lowercased()
            }
            Analytics.logEvent("dictionary_open", parameters: ["source": "tab"])
            viewModel.searchText = searchText
        }
        .onDisappear {
            Analytics.logEvent("dictionary_close", parameters: ["source": "tab"])
        }
        .onChange(of: searchText) {
            viewModel.searchText = searchText
        }
        .onChange(of: viewModel.filteredCanonicals.map { $0.canonical }) {
            let count = viewModel.filteredCanonicals.count
            if count == 0 {
                selected = 0
                viewModel.activeLetter = nil
            } else {
                let q = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                var best = selected
                if !q.isEmpty {
                    best = viewModel.filteredCanonicals.firstIndex(where: { $0.canonical.lowercased().hasPrefix(q) })
                    ?? viewModel.filteredCanonicals.firstIndex(where: { group in
                        group.variants.contains { $0.slang.lowercased().hasPrefix(q) }
                    })
                    ?? 0
                }
                selected = min(max(0, best), count - 1)
            }
            scrollToIndexTrigger = selected
            updateActiveLetterFromSelection()
        }
        .onChange(of: viewModel.searchText) {
            let count = viewModel.filteredCanonicals.count
            guard count > 0 else { return }
            let q = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            var best = selected
            if !q.isEmpty {
                best = viewModel.filteredCanonicals.firstIndex(where: { $0.canonical.lowercased().hasPrefix(q) })
                ?? viewModel.filteredCanonicals.firstIndex(where: { group in
                    group.variants.contains { $0.slang.lowercased().hasPrefix(q) }
                })
                ?? 0
            }
            selected = min(max(0, best), count - 1)
            scrollToIndexTrigger = selected
            updateActiveLetterFromSelection()
        }
        .onChange(of: selected) {
            updateActiveLetterFromSelection()
        }
        .onChange(of: viewModel.activeLetter) {
            if let l = viewModel.activeLetter, !l.isEmpty {
                lastOverlayLetter = l
            } else if viewModel.filteredCanonicals.indices.contains(selected), let first = viewModel.filteredCanonicals[selected].canonical.first {
                lastOverlayLetter = String(first).lowercased()
            }
        }
        .animation(nil, value: viewModel.filteredCanonicals.map { $0.canonical })
    }
    
    private var optimizedAlphabetSidebar: some View {
        let letters = Self.letters
        return GeometryReader { geo in
            VStack(spacing: 0) {
                ForEach(letters, id: \.self) { letter in
                    Text(letter)
                        .font(.system(size: 11, design: .serif))
                        .foregroundColor(viewModel.activeLetter == letter ? AppColor.Button.Text.primary : AppColor.Text.secondary)
                        .frame(width: 20, height: 18)
                        .background(
                            Circle().fill(viewModel.activeLetter == letter ? AppColor.Text.primary : .clear)
                        )
                }
            }
            .frame(width: 20, height: geo.size.height, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let localY = g.location.y
                        let step = max(1.0, geo.size.height / CGFloat(letters.count))
                        var index = Int((localY / step).rounded(.down))
                        index = min(max(0, index), letters.count - 1)
                        let letter = letters[index]
                        if viewModel.activeLetter != letter || !viewModel.isDraggingLetter {
                            viewModel.handleLetterDrag(letter)
                            jumpAnimated = false
                            if let jumpIndex = viewModel.indexForLetter(letter) {
                                if selected != jumpIndex && scrollToIndexTrigger != jumpIndex {
                                    let now = CACurrentMediaTime()
                                    if now - lastJumpTime > 0.05 {
                                        lastJumpTime = now
                                        scrollToIndexTrigger = jumpIndex
                                    }
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        viewModel.handleLetterDragEnd()
                        jumpAnimated = true
                    }
            )
            .padding(.trailing, 6)
        }
        .frame(width: 26)
    }

    private func updateActiveLetterFromSelection() {
        guard viewModel.filteredCanonicals.indices.contains(selected) else { return }
        if let first = viewModel.filteredCanonicals[selected].canonical.first {
            viewModel.activeLetter = String(first).lowercased()
        }
    }
}

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayers: [AVAudioPlayer] = []
    private let poolSize = 8
    private var currentPlayerIndex = 0
    
    private var lastPlayTime: TimeInterval = 0
    private var scrollVelocity: Double = 0
    private var velocityHistory: [Double] = []
    private let maxVelocityHistory = 5
    private var smoothedVelocity: Double = 0
    
    private let smoothingFactor: Double = 0.3
    
    private var dynamicInterval: TimeInterval {
        switch smoothedVelocity {
        case 0..<0.2:      return 0.07
        case 0.2..<0.4:    return 0.06
        case 0.4..<0.6:    return 0.05
        case 0.6..<0.8:    return 0.04
        case 0.8..<1.2:    return 0.03
        case 1.2..<2.0:    return 0.02
        case 2.0..<3.5:    return 0.018
        default:           return 0.013
        }
    }
    
    private var adaptiveVolume: Float {
        let normalizedVelocity = min(smoothedVelocity / 4.0, 1.0)
        let easedValue = 1.0 - pow(normalizedVelocity, 0.7)
        return Float(0.12 + (easedValue * 0.1))
    }
    
    private var shouldVaryPitch = false
    
    private init() {
        setupAudioSession()
        createAudioPlayerPool()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers, .allowBluetoothHFP]
            )
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.005)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    private func createAudioPlayerPool() {
        guard let url = Bundle.main.url(forResource: "click-1", withExtension: "wav") else {
            print("Sound file not found")
            return
        }
        
        for _ in 0..<poolSize {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.volume = 0.25
                player.numberOfLoops = 0
                player.enableRate = shouldVaryPitch
                audioPlayers.append(player)
            } catch {
                print("Failed to create audio player: \(error)")
            }
        }
    }
    
    func updateScrollVelocity(_ velocity: Double) {
        let newVelocity = abs(velocity)
        
        if smoothedVelocity == 0 {
            smoothedVelocity = newVelocity
        } else {
            smoothedVelocity = (smoothingFactor * newVelocity) + ((1 - smoothingFactor) * smoothedVelocity)
        }
        
        velocityHistory.append(newVelocity)
        if velocityHistory.count > maxVelocityHistory {
            velocityHistory.removeFirst()
        }
        
        scrollVelocity = newVelocity
    }
    
    func playClick(withVelocity velocity: Double = 0) {
        let defaults = UserDefaults(suiteName: "group.prammmoe.SLNG") ?? .standard
        let enabled: Bool = {
            if defaults.object(forKey: "soundEffectEnabled") == nil { return true }
            return defaults.bool(forKey: "soundEffectEnabled")
        }()
        guard enabled else { return }
        let currentTime = CACurrentMediaTime()
        
        if velocity > 0 {
            updateScrollVelocity(velocity)
        }
        
        guard currentTime - lastPlayTime >= dynamicInterval else { return }
        lastPlayTime = currentTime
        
        guard !audioPlayers.isEmpty else { return }
        
        let player = audioPlayers[currentPlayerIndex]
        currentPlayerIndex = (currentPlayerIndex + 1) % audioPlayers.count
        
        if player.isPlaying {
            player.stop()
        }
        
        player.volume = adaptiveVolume
        
        if shouldVaryPitch {
            let pitchVariation = 0.95 + (CGFloat.random(in: 0...0.1))
            player.rate = Float(pitchVariation)
        }
        
        player.currentTime = 0
        player.play()
    }
    
    func decayVelocity() {
        smoothedVelocity *= 0.85
        if smoothedVelocity < 0.01 {
            smoothedVelocity = 0
        }
    }
    
    func resetVelocity() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            for _ in 0..<10 {
                self.decayVelocity()
                Thread.sleep(forTimeInterval: 0.02)
            }
            self.velocityHistory.removeAll()
            self.scrollVelocity = 0
            self.smoothedVelocity = 0
        }
    }
    
    func playSystemClick(intensity: CGFloat = 0.5) {
        let defaults = UserDefaults(suiteName: "group.prammmoe.SLNG") ?? .standard
        let soundOn: Bool = {
            if defaults.object(forKey: "soundEffectEnabled") == nil { return true }
            return defaults.bool(forKey: "soundEffectEnabled")
        }()
        if soundOn {
            AudioServicesPlaySystemSound(1104)
        }

        if Haptics.isEnabled {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred(intensity: intensity)
        }
    }
    
    func setPitchVariation(enabled: Bool) {
        shouldVaryPitch = enabled
        for player in audioPlayers {
            player.enableRate = enabled
        }
    }
}

public struct SwiftUIWheelPicker<Item>: View {
    private let items: [Item]
    @Binding private var selection: Int
    private let content: (Item, Int, Bool) -> AnyView
    private let onSelectedTap: ((Int) -> Void)?
    
    @Binding var scrollToIndexTrigger: Int?
    @Binding var jumpAnimated: Bool
    
    @State private var centers: [Int: CGFloat] = [:]
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var dragging = false
    @State private var engine = UIImpactFeedbackGenerator(style: .heavy)
    
    @State private var visibleRange: Range<Int> = 0..<10
    @State private var containerCenterY: CGFloat = 0
    
    private let soundManager = SoundManager.shared
    @State private var lastSelectionTime: TimeInterval = 0
    @State private var selectionVelocity: Double = 0
    @State private var velocityUpdateTimer: Timer?
    @State private var lastSelection: Int = 0
    
    @State private var isQuickScrolling = false

    public init(
        items: [Item],
        selection: Binding<Int>,
        scrollToIndexTrigger: Binding<Int?> = .constant(nil),
        jumpAnimated: Binding<Bool> = .constant(true),
        onSelectedTap: ((Int) -> Void)? = nil,
        content: @escaping (Item, Int, Bool) -> AnyView
    ) {
        self.items = items
        self._selection = selection
        self._scrollToIndexTrigger = scrollToIndexTrigger
        self._jumpAnimated = jumpAnimated
        self.onSelectedTap = onSelectedTap
        self.content = content
    }
    
    public var body: some View {
        GeometryReader { outerGeo in
                   ZStack {
                       ScrollViewReader { proxy in
                           ScrollView(.vertical, showsIndicators: false) {
                               LazyVStack(spacing: 24) {
                                   Color.clear.frame(height: outerGeo.size.height / 2)
                                   
                                   ForEach(items.indices, id: \.self) { idx in
                                       itemRow(for: idx)
                                           .background(
                                               GeometryReader { geo in
                                                   let midY = geo.frame(in: .global).midY
                                                   Color.clear
                                                       .preference(
                                                           key: RowCenterKey.self,
                                                           value: [RowCenter(id: idx, midY: midY)]
                                                       )
                                               }
                                           )
                                   }
                                   
                                   Color.clear.frame(height: outerGeo.size.height / 2)
                               }
                           }
                           .onAppear {
                               scrollProxy = proxy
                               engine.prepare()
                               lastSelection = selection
                               
                               setupVelocityTimer()
                               
                               DispatchQueue.main.async {
                                   proxy.scrollTo(selection, anchor: .center)
                               }
                           }
                           .onDisappear {
                               velocityUpdateTimer?.invalidate()
                           }
                           .onPreferenceChange(RowCenterKey.self) { values in
                               guard !dragging else { return }
                               guard !values.isEmpty else { return }
                               
                               let filtered = values.filter { visibleRange.contains($0.id) }
                               for v in filtered {
                                   centers[v.id] = v.midY
                               }
                               containerCenterY = outerGeo.frame(in: .global).midY
                               updateSelection(containerCenterY: containerCenterY, shouldFeedback: false)
                           }
                           .gesture(
                               DragGesture(minimumDistance: 1, coordinateSpace: .global)
                                   .onChanged { _ in
                                       if !dragging {
                                           dragging = true
                                           isQuickScrolling = true
                                       }
                                   }
                                   .onEnded { _ in
                                       dragging = false
                                       
                                       DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                           if Haptics.isEnabled {
                                               engine.impactOccurred(intensity: 0.4)
                                           }

                                           isQuickScrolling = false
                                           soundManager.resetVelocity()
                                           lastSelectionTime = 0
                                           selectionVelocity = 0
                                       }
                                       
                                       snapToNearest(containerCenterY: outerGeo.frame(in: .global).midY)
                                   }
                           )
                       }
                   }
               }
               .onChange(of: scrollToIndexTrigger) {
                   guard let index = scrollToIndexTrigger else { return }
                   scrollToIndex(index, animated: true)
                   scrollToIndexTrigger = nil
               }
    }

    @ViewBuilder
    private func itemRow(for idx: Int) -> some View {
        let isSelected = idx == selection
        content(items[idx], idx, isSelected)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                if isSelected {
                    onSelectedTap?(idx)
                } else {
                    updateSelection(to: idx, animated: true)
                }
            }
            .onAppear {
                updateVisibleRange(around: idx)
            }
    }
    
    private func setupVelocityTimer() {
        velocityUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            if !dragging && selectionVelocity > 0.01 {
                soundManager.decayVelocity()
            }
        }
    }

    private func updateSelection(containerCenterY: CGFloat, shouldFeedback: Bool) {
        guard !centers.isEmpty else { return }
        let visibleCenters = centers.filter { visibleRange.contains($0.key) }
        guard let nearest = visibleCenters.min(by: {
            abs($0.value - containerCenterY) < abs($1.value - containerCenterY)
        })?.key else { return }

        if nearest != selection {
            let currentTime = CACurrentMediaTime()
            
            if lastSelectionTime > 0 {
                let timeDelta = currentTime - lastSelectionTime
                let indexDelta = abs(nearest - lastSelection)
                
                let rawVelocity = timeDelta > 0 ? Double(indexDelta) / timeDelta : 0
                
                selectionVelocity = (selectionVelocity * 0.6) + (rawVelocity * 0.4)
            }
            
            lastSelectionTime = currentTime
            lastSelection = selection
            selection = nearest
            
            DispatchQueue.global(qos: .userInteractive).async {
                soundManager.playClick(withVelocity: selectionVelocity)
            }
            
            if shouldFeedback && Haptics.isEnabled {
                let normalizedVelocity = min(selectionVelocity / 15.0, 1.0)
                let intensity = max(0.2, 1.0 - CGFloat(normalizedVelocity * 0.7))
                
                DispatchQueue.main.async {
                    engine.impactOccurred(intensity: intensity)
                }
            }
        }
    }

    private func snapToNearest(containerCenterY: CGFloat) {
        guard !centers.isEmpty else { return }
        let visibleCenters = centers.filter { visibleRange.contains($0.key) }
        guard let nearest = visibleCenters.min(by: {
            abs($0.value - containerCenterY) < abs($1.value - containerCenterY)
        })?.key else { return }
        updateSelection(to: nearest, animated: true)
    }

    private func updateSelection(to newIndex: Int, animated: Bool) {
        guard newIndex >= 0 && newIndex < items.count else { return }
        
        selection = newIndex
        updateVisibleRange(around: newIndex)
        guard let proxy = scrollProxy else { return }
        
        let distance = abs(newIndex - lastSelection)
        let _: Double = animated ? min(0.3, max(0.15, Double(distance) * 0.02)) : 0
        
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(newIndex, anchor: .center)
        }
        
            if Haptics.isEnabled {
                engine.impactOccurred(intensity: 0.6)
            }
    }

    public func scrollToIndex(_ index: Int, animated: Bool = true) {
        guard index >= 0 && index < items.count else { return }
        selection = index
        updateVisibleRange(around: index)
        guard let proxy = scrollProxy else { return }
        
        let shouldAnimate = animated && jumpAnimated
        if shouldAnimate {
            withAnimation(.easeOut(duration: 0.18)) {
                proxy.scrollTo(index, anchor: .center)
            }
        } else {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                proxy.scrollTo(index, anchor: .center)
            }
        }
        
        if Haptics.isEnabled {
            engine.impactOccurred(intensity: 0.5)
        }

        DispatchQueue.main.async {
            snapToNearest(containerCenterY: containerCenterY > 0 ? containerCenterY : 0)
        }
    }

    private func updateVisibleRange(around index: Int) {
        let buffer = 10
        let start = max(0, index - buffer)
        let end = min(items.count, index + buffer)
        visibleRange = start..<end
    }
}

private struct RowCenter: Equatable { let id: Int; let midY: CGFloat }
private struct RowCenterKey: PreferenceKey {
    static var defaultValue: [RowCenter] = []
    static func reduce(value: inout [RowCenter], nextValue: () -> [RowCenter]) {
        value.append(contentsOf: nextValue())
    }
}
final class KeyboardObserver: ObservableObject {
    @Published var height: CGFloat = 0
    private var cancellables: Set<AnyCancellable> = []

    init() {
        let willChange = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)

        willChange
            .merge(with: willHide)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self = self else { return }
                self.updateHeight(from: notification)
            }
            .store(in: &cancellables)
    }

    private func updateHeight(from notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
        let screenHeight = UIScreen.main.bounds.height
        let isHidden = endFrame.origin.y >= screenHeight
        let bottomSafeArea = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .safeAreaInsets.bottom ?? 0

        let rawHeight = isHidden ? 0 : endFrame.height
        height = max(0, rawHeight - bottomSafeArea)
    }
}
