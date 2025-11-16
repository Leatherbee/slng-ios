//
//  DictionaryView.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 07/11/25.
//  Optimized for large data sets and alphabet jumping.
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

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background layer
            AppColor.Background.primary
                .ignoresSafeArea()
            
            // Main content
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
                        let rowHeight: CGFloat = 48
                        let (fontSize, opacity): (CGFloat, Double)
                        switch distance {
                        case 0: (fontSize, opacity) = (64, 1.0)
                        case 1: (fontSize, opacity) = (48, 0.8)
                        case 2: (fontSize, opacity) = (34, 0.6)
                        case 3: (fontSize, opacity) = (28, 0.4)
                        case 4: (fontSize, opacity) = (20, 0.2)
                        default: (fontSize, opacity) = (20, 0.0)
                        }

                        return AnyView(
                            HStack(spacing: 32) {
                                Text(item)
                                    .font(.system(size: fontSize, weight: isSelected ? .bold : .medium, design: .serif))
                                    .padding(.leading, 8)
                                    .opacity(opacity)
                                    .scaleEffect(isSelected ? 1.1 : 1.0)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .layoutPriority(1)

                                if isSelected {
                                    Image(systemName: "arrow.right")
                                        .resizable()
                                        .frame(width: 48, height: 24)
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
                    .frame(height: 573)
                    .frame(maxWidth: .infinity)
                    .clipped()

                    optimizedAlphabetSidebar
                }
            }
            .padding()
            
            // Letter overlay - MUST be separate to avoid blocking search
            VStack {
                let displayLetter: String = {
                    if let l = viewModel.activeLetter, !l.isEmpty { return l }
                    return lastOverlayLetter
                }()
                Text(displayLetter.uppercased())
                    .font(.system(size: 64, design: .serif))
                    .foregroundColor(AppColor.Text.secondary)
                    .allowsHitTesting(false) // PENTING: jangan block interaction
            }
            .frame(width: 128, height: 128)
            .background(.clear)
            .clipShape(.circle)
            .allowsHitTesting(false) // PENTING: jangan block interaction
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
            } else if selected >= count {
                selected = max(0, count - 1)
            }
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

// MARK: - Ultra Smooth Sound Manager dengan Advanced Audio Engine
class SoundManager {
    static let shared = SoundManager()
    
    // Expanded audio player pool untuk ultra smooth playback
    private var audioPlayers: [AVAudioPlayer] = []
    private let poolSize = 8 // Lebih banyak player untuk smoothness maksimal
    private var currentPlayerIndex = 0
    
    // Advanced velocity tracking dengan smoothing
    private var lastPlayTime: TimeInterval = 0
    private var scrollVelocity: Double = 0
    private var velocityHistory: [Double] = []
    private let maxVelocityHistory = 5 // Lebih banyak history untuk smoothing lebih baik
    private var smoothedVelocity: Double = 0
    
    // Exponential smoothing untuk velocity (lebih responsive)
    private let smoothingFactor: Double = 0.3
    
    // Ultra dynamic intervals dengan lebih banyak gradasi
    private var dynamicInterval: TimeInterval {
        switch smoothedVelocity {
        case 0..<0.2:      return 0.07   // Sangat lambat
        case 0.2..<0.4:    return 0.06   // Lambat
        case 0.4..<0.6:    return 0.05  // Sedang lambat
        case 0.6..<0.8:    return 0.04  // Sedang
        case 0.8..<1.2:    return 0.03  // Sedang cepat
        case 1.2..<2.0:    return 0.02  // Cepat
        case 2.0..<3.5:    return 0.018  // Sangat cepat
        default:           return 0.013  // Ultra cepat
        }
    }
    
    // Volume curve yang lebih smooth dengan easing
    private var adaptiveVolume: Float {
        let normalizedVelocity = min(smoothedVelocity / 4.0, 1.0)
        // Ease-out curve untuk transisi volume yang lebih smooth
        let easedValue = 1.0 - pow(normalizedVelocity, 0.7)
        return Float(0.12 + (easedValue * 0.1)) // Range: 0.12 - 0.28
    }
    
    // Pitch variation untuk variety (optional, bisa di-enable/disable)
    private var shouldVaryPitch = false
    
    private init() {
        setupAudioSession()
        createAudioPlayerPool()
    }
    
    private func setupAudioSession() {
        do {
            // Optimize audio session untuk low latency
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers, .allowBluetooth]
            )
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.005) // Low latency
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
        
        // Create larger pool with optimized settings
        for _ in 0..<poolSize {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.volume = 0.25
                player.numberOfLoops = 0
                player.enableRate = shouldVaryPitch // Enable pitch variation if needed
                audioPlayers.append(player)
            } catch {
                print("Failed to create audio player: \(error)")
            }
        }
    }
    
    // Exponential moving average untuk velocity smoothing
    func updateScrollVelocity(_ velocity: Double) {
        let newVelocity = abs(velocity)
        
        // Exponential smoothing
        if smoothedVelocity == 0 {
            smoothedVelocity = newVelocity
        } else {
            smoothedVelocity = (smoothingFactor * newVelocity) + ((1 - smoothingFactor) * smoothedVelocity)
        }
        
        // Keep history for additional smoothing
        velocityHistory.append(newVelocity)
        if velocityHistory.count > maxVelocityHistory {
            velocityHistory.removeFirst()
        }
        
        scrollVelocity = newVelocity
    }
    
    // Ultra smooth playback dengan advanced features
    func playClick(withVelocity velocity: Double = 0) {
        let currentTime = CACurrentMediaTime()
        
        // Update velocity dengan smoothing
        if velocity > 0 {
            updateScrollVelocity(velocity)
        }
        
        // Ultra adaptive throttling
        guard currentTime - lastPlayTime >= dynamicInterval else { return }
        lastPlayTime = currentTime
        
        guard !audioPlayers.isEmpty else { return }
        
        // Round-robin through player pool
        let player = audioPlayers[currentPlayerIndex]
        currentPlayerIndex = (currentPlayerIndex + 1) % audioPlayers.count
        
        // Stop player jika masih playing (untuk ultra responsive sound)
        if player.isPlaying {
            player.stop()
        }
        
        // Apply adaptive volume dengan smooth transition
        player.volume = adaptiveVolume
        
        // Optional: Vary pitch slightly untuk variety (more natural feel)
        if shouldVaryPitch {
            let pitchVariation = 0.95 + (CGFloat.random(in: 0...0.1))
            player.rate = Float(pitchVariation)
        }
        
        // Reset and play
        player.currentTime = 0
        player.play()
    }
    
    // Smooth velocity decay saat tidak ada input
    func decayVelocity() {
        smoothedVelocity *= 0.85 // Decay factor
        if smoothedVelocity < 0.01 {
            smoothedVelocity = 0
        }
    }
    
    // Reset dengan smooth transition
    func resetVelocity() {
        // Smooth decay instead of instant reset
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
    
    // System sound alternative dengan ultra smooth haptic
    func playSystemClick(intensity: CGFloat = 0.5) {
        AudioServicesPlaySystemSound(1104)
        
        // Ultra smooth haptic dengan proper intensity
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }
    
    // Enable/disable pitch variation
    func setPitchVariation(enabled: Bool) {
        shouldVaryPitch = enabled
        for player in audioPlayers {
            player.enableRate = enabled
        }
    }
}

// MARK: - Ultra Smooth SwiftUIWheelPicker
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
    @State private var engine = UIImpactFeedbackGenerator(style: .light)
    
    @State private var visibleRange: Range<Int> = 0..<10
    @State private var containerCenterY: CGFloat = 0
    
    // Ultra smooth sound tracking
    private let soundManager = SoundManager.shared
    @State private var lastSelectionTime: TimeInterval = 0
    @State private var selectionVelocity: Double = 0
    @State private var velocityUpdateTimer: Timer?
    @State private var lastSelection: Int = 0
    
    // Smooth animation tracking
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
                        let itemHeight: CGFloat = 48
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
                        
                        // Setup continuous velocity updates untuk smoothness
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
                                
                                // Smooth velocity reset dengan decay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
    
    // Setup timer untuk continuous velocity smoothing
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
            
            // Hitung velocity dengan smoothing lebih baik
            if lastSelectionTime > 0 {
                let timeDelta = currentTime - lastSelectionTime
                let indexDelta = abs(nearest - lastSelection)
                
                // Velocity berdasarkan jarak dan waktu
                let rawVelocity = timeDelta > 0 ? Double(indexDelta) / timeDelta : 0
                
                // Smooth velocity calculation
                selectionVelocity = (selectionVelocity * 0.6) + (rawVelocity * 0.4)
            }
            
            lastSelectionTime = currentTime
            lastSelection = selection
            selection = nearest
            
            // Ultra smooth sound playback
            DispatchQueue.global(qos: .userInteractive).async {
                soundManager.playClick(withVelocity: selectionVelocity)
            }
            
            // Smooth haptic dengan velocity-based intensity
            if shouldFeedback {
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
        
        // Smooth animation dengan variable duration
        let distance = abs(newIndex - lastSelection)
        let duration: Double = animated ? min(0.3, max(0.15, Double(distance) * 0.02)) : 0
        
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(newIndex, anchor: .center)
        }
        
        // Gentle haptic
        engine.impactOccurred(intensity: 0.6)
    }

    public func scrollToIndex(_ index: Int, animated: Bool = true) {
        guard index >= 0 && index < items.count else { return }
        selection = index
        updateVisibleRange(around: index)
        guard let proxy = scrollProxy else { return }
        
        // Ultra smooth animation untuk jump, bisa dimatikan saat drag alphabet
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
        
        engine.impactOccurred(intensity: 0.5)

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
// MARK: - Keyboard Observer
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
// Preview
//#Preview {
//    DictionaryView()
//        .environment(PopupManager())
//}
