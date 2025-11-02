//
//  BurstTrapesiumView.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 01/11/25.
//

import SwiftUI
import SwiftUI

struct BurstTrapesiumView: View {
    @State private var progress: Double = 0
    let spread: CGFloat = 1.6   // semakin besar, semakin renggang

    var body: some View {
        ZStack {
            // MARK: Top Left
            BurstPiece(anchorAtTip: true)
                .scaleEffect(y: -1)
                .rotationEffect(.degrees(-20))
                .offset(x: -70 * spread, y: -120 * spread)
                .animation(.spring(response: 0.6, dampingFraction: 0.55)
                    .delay(0.0), value: progress)

            // MARK: Top Center
            BurstPiece(anchorAtTip: true)
                .scaleEffect(y: -1)
                .rotationEffect(.degrees(0))
                .offset(x: 0, y: -160 * spread)
                .animation(.spring(response: 0.6, dampingFraction: 0.55)
                    .delay(0.05), value: progress)

            // MARK: Top Right
            BurstPiece(anchorAtTip: true)
                .scaleEffect(y: -1)
                .rotationEffect(.degrees(20))
                .offset(x: 70 * spread, y: -120 * spread)
                .animation(.spring(response: 0.6, dampingFraction: 0.55)
                    .delay(0.1), value: progress)

            // MARK: Bottom Left
            BurstPiece(anchorAtTip: true)
                .rotationEffect(.degrees(12))
                .offset(x: -60 * spread, y: 150 * spread)
                .animation(.spring(response: 0.6, dampingFraction: 0.55)
                    .delay(0.15), value: progress)

            // MARK: Bottom Right
            BurstPiece(anchorAtTip: true)
                .rotationEffect(.degrees(-12))
                .offset(x: 60 * spread, y: 150 * spread)
                .animation(.spring(response: 0.6, dampingFraction: 0.55)
                    .delay(0.2), value: progress)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.1)) { progress = 0.3 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.interpolatingSpring(stiffness: 80, damping: 6)) { progress = 1.0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeIn(duration: 0.3)) { progress = 0 }
            }
        }
    }
}


struct BurstPiece: View {
    @State private var elongation: CGFloat = 0.1
    @State private var slideOffset: CGFloat = 0
    @State private var opacity: Double = 0.0
    var anchorAtTip: Bool

    var body: some View {
        TrapeziumShape()
            .fill(Color.black.opacity(0.8))
            .frame(width: 40, height: 350)
            // Scale from the sharp tip (anchor: .top)
            .scaleEffect(y: elongation, anchor: .top)
            .offset(y: slideOffset)
            .opacity(opacity)
            .onAppear {
                // Phase 1: Appear small at tip (point A)
                withAnimation(.easeOut(duration: 0.15)) {
                    opacity = 1
                    elongation = 0.3
                }
                
                // Phase 2: Elongate outward from the sharp end toward point B
                withAnimation(.interpolatingSpring(stiffness: 100, damping: 9).delay(0.15)) {
                    elongation = 1.3
                }
                
                // Phase 3: Point B pulls the entire shape towards itself (away from origin)
                withAnimation(.interpolatingSpring(stiffness: 100, damping: 9).delay(0.6)) {
                    // Slide the entire shape in the direction of B (negative = downward from tip)
                    slideOffset = -160
                    // Shrink as it gets pulled with spring animation
                    elongation = 0.1
                }
                
                withAnimation(.interpolatingSpring(stiffness: 100, damping: 9).delay(0.6)) {
                    // Slide the entire shape in the direction of B (negative = downward from tip)
                    slideOffset = 160
                    // Shrink as it gets pulled with spring animation
                    elongation = 0.3
                }
                
                // Fade out separately with easing
                withAnimation(.easeIn(duration: 0.6).delay(0.6)) {
                    opacity = 0
                }
            }
    }
}

struct TrapeziumShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Define the SHARP tip at top, widening downward
        let tipWidth: CGFloat = 2
        path.move(to: CGPoint(x: rect.midX, y: rect.minY)) // sharp tip
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX - tipWidth, y: rect.minY + 2))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        Text("Gw udh males sama kalian")
            .font(.system(size: 28, weight: .semibold))
            .foregroundColor(.white.opacity(0.4))
        BurstTrapesiumView()
    }
}
