//
//  RecordButton.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 18/11/25.
//

import SwiftUI
import AVFoundation

struct RecordButton: View {
    @Binding var isRecording: Bool
    var onStart: () -> Void = {}
    var onStopAndTranscribe: () -> Void = {}
    var onCancel: () -> Void = {}
    var audioLevel: Float = -160
    
    @State private var timer: Timer?
    @State private var pulseScale: CGFloat = 1.0
    @State private var position: CGPoint = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var dripPlayer: AVAudioPlayer?
    @State private var releasePlayer: AVAudioPlayer?
    @State private var pressStartAt: Date?
    @State private var isPressed: Bool = false
    @State private var buttonScale: CGFloat = 1.0
    private let minHoldDuration: TimeInterval = 1.4
    @AppStorage("soundEffectEnabled", store: UserDefaults(suiteName: "group.prammmoe.SLNG")!) private var soundEffectEnabled: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated ripples when recording
                if isRecording {
                    let normalized = max(0, min(1, CGFloat((audioLevel + 160) / 160)))
    
                    Circle()
                        .fill(AppColor.Button.primary.opacity(0.14))
                        .frame(width: 140, height: 140)
                        .scaleEffect(1 + normalized * 1.0)
                        .animation(.easeOut(duration: 0.1), value: normalized)
                    
                    Circle()
                        .fill(AppColor.Button.primary.opacity(0.10))
                        .frame(width: 180, height: 180)
                        .scaleEffect(1 + normalized * 1.5)
                        .animation(.easeOut(duration: 0.15), value: normalized)
                    
                    Circle()
                        .fill(AppColor.Button.primary.opacity(0.20))
                        .frame(width: 90, height: 90)
                        .scaleEffect(buttonScale)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonScale)
                }

                // Hit area when not recording
                if !isRecording {
                    Circle()
                        .fill(Color.gray.opacity(0.0001))
                        .frame(width: 200, height: 200)
                        .overlay(
                            Circle().stroke(Color.gray.opacity(0.01), lineWidth: 1)
                        )
                        .scaleEffect(buttonScale)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonScale)
                        .allowsHitTesting(true)
                }
            }
            .position(
                x: position.x + dragOffset.width,
                y: position.y + dragOffset.height
            )
            .frame(width: geometry.size.width, height: geometry.size.height)
            .zIndex(999)
            
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            position.x += value.translation.width
                            position.y += value.translation.height
                            dragOffset = .zero
                            position.x = min(max(position.x, 40), geometry.size.width - 40)
                            position.y = min(max(position.y, 40), geometry.size.height - 40)
                        }
                    }
            )
            
            .onLongPressGesture(
                minimumDuration: 0.3,
                maximumDistance: 50,
                pressing: { pressing in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = pressing
                        buttonScale = pressing ? 0.9 : 1.0
                    }
                    
                    if pressing && !isRecording {
                        isRecording = true
                        onStart()
                        playDripSound()
                        pressStartAt = Date()
                        startSonar()
                    } else if !pressing && isRecording {
                        isRecording = false
                        playReleaseSound()
                        let duration = Date().timeIntervalSince(pressStartAt ?? Date())
                        if duration >= minHoldDuration {
                            onStopAndTranscribe()
                        } else {
                            onCancel()
                        }
                        pressStartAt = nil
                        stopSonar()
                    }
                },
                perform: {}
            )
            .onAppear {
                if position == .zero {
                    position = CGPoint(
                        x: geometry.size.width / 2,
                        y: geometry.size.height - 120
                    )
                }
                if soundEffectEnabled {
                    if dripPlayer == nil, let url = Bundle.main.url(forResource: "water-drip", withExtension: "mp3") {
                        dripPlayer = try? AVAudioPlayer(contentsOf: url)
                        dripPlayer?.volume = 0.85
                        dripPlayer?.prepareToPlay()
                    }
                    if releasePlayer == nil, let url = Bundle.main.url(forResource: "water-drip", withExtension: "mp3") {
                        releasePlayer = try? AVAudioPlayer(contentsOf: url)
                        releasePlayer?.volume = 0.85
                        releasePlayer?.prepareToPlay()
                    }
                }
            }
        }
    }
    
    private func playDripSound() {
        guard soundEffectEnabled else { return }
        if dripPlayer == nil, let url = Bundle.main.url(forResource: "water-drip", withExtension: "mp3") {
            dripPlayer = try? AVAudioPlayer(contentsOf: url)
            dripPlayer?.volume = 0.85
            dripPlayer?.prepareToPlay()
        }
        dripPlayer?.currentTime = 0
        dripPlayer?.play()
    }

    private func playReleaseSound() {
        guard soundEffectEnabled else { return }
        if releasePlayer == nil, let url = Bundle.main.url(forResource: "water-drip", withExtension: "mp3") {
            releasePlayer = try? AVAudioPlayer(contentsOf: url)
            releasePlayer?.volume = 0.9
            releasePlayer?.prepareToPlay()
        }
        releasePlayer?.currentTime = 0
        releasePlayer?.play()
    }

    private func startSonar() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { t in
            guard isRecording else { t.invalidate(); return }
            withAnimation(.easeInOut(duration: 0.4)) {
                pulseScale = (pulseScale >= 1.5) ? 1.0 : 1.5
            }
        }
    }
    
    private func stopSonar() {
        timer?.invalidate()
        timer = nil
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            pulseScale = 1.0
        }
    }
}
