/**
 To adjust the trapezium effect:

 Change tipWidth = baseWidth * 0.3 to a smaller number (like 0.1) for more dramatic taper
 Adjust baseWidth range in CGFloat(drand48() * 3 + 2) for thicker/thinner rays overall
 */

import SwiftUI
import CoreGraphics

// MARK: - Shape dengan seed random dan trapezium shape
struct VariableSunburstShape: Shape {
    var seed: Int
    var progress: CGFloat
    var shrink: CGFloat
    var scale: CGFloat
    
    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, CGFloat> {
        get { AnimatablePair(AnimatablePair(progress, shrink), scale) }
        set {
            progress = newValue.first.first
            shrink = newValue.first.second
            scale = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        srand48(seed)
        
        let maxLength = hypot(rect.width, rect.height) * 0.6 * scale
        let clusters = [
            (start: 0.0, end: 0.3, density: 2),
            (start: 0.3, end: 0.55, density: 1),
            (start: 0.55, end: 0.7, density: 2),
            (start: 0.7, end: 1.0, density: 1)
        ]
        
        for cluster in clusters {
            for _ in 0..<cluster.density {
                let angle = (cluster.start + drand48() * (cluster.end - cluster.start)) * 2 * .pi
                
                let baseStart = CGFloat(60 + drand48() * 80) * scale
                let baseLength = CGFloat(drand48()) * 0.8 * maxLength + maxLength * 0.6
                
                let finalLength = baseLength * progress
                let startRadius = baseStart + (finalLength * shrink)
                if finalLength <= startRadius { continue }
                
                // Calculate perpendicular angle for trapezium width
                let perpAngle1 = angle + .pi / 2
                let perpAngle2 = angle - .pi / 2
                
                // Width at start (narrow, near center) and end (wider, far out)
                let endWidth = CGFloat(drand48() * 6 + 5) * scale  // End width: 2-5 points (wider)
                let startWidth = endWidth * 0.3  // Start is 30% of end width (narrower)
                
                // Create trapezium vertices
                // Start points (narrower, near center)
                let startLeft = CGPoint(
                    x: center.x + cos(angle) * startRadius + cos(perpAngle1) * startWidth,
                    y: center.y + sin(angle) * startRadius + sin(perpAngle1) * startWidth
                )
                let startRight = CGPoint(
                    x: center.x + cos(angle) * startRadius + cos(perpAngle2) * startWidth,
                    y: center.y + sin(angle) * startRadius + sin(perpAngle2) * startWidth
                )
                
                // End points (wider, far from center)
                let endLeft = CGPoint(
                    x: center.x + cos(angle) * finalLength + cos(perpAngle1) * endWidth,
                    y: center.y + sin(angle) * finalLength + sin(perpAngle1) * endWidth
                )
                let endRight = CGPoint(
                    x: center.x + cos(angle) * finalLength + cos(perpAngle2) * endWidth,
                    y: center.y + sin(angle) * finalLength + sin(perpAngle2) * endWidth
                )
                
                // ✅ Draw trapezium (narrow at start, wide at end)
                path.move(to: startLeft)
                path.addLine(to: endLeft)
                path.addLine(to: endRight)
                path.addLine(to: startRight)
                path.closeSubpath()
            }
        }
        return path
    }
}

// MARK: - Layer data untuk depth effect
struct RayLayer: Identifiable {
    let id = UUID()
    let seed: Int
    let scale: CGFloat
    let opacity: Double
    let delay: Double
}

// MARK: - Reusable SunburstView
struct SunburstView: View {
    @Binding var trigger: Bool
    @State private var progress: CGFloat = 0
    @State private var shrink: CGFloat = 0
    @State private var layerScales: [CGFloat] = []
    @State private var layers: [RayLayer] = []
    
    var body: some View {
        ZStack {
            ForEach(Array(layers.enumerated()), id: \.element.id) { index, layer in
                VariableSunburstShape(
                    seed: layer.seed,
                    progress: progress,
                    shrink: shrink,
                    scale: index < layers.count ? layerScales[index] : layer.scale
                )
                .fill(Color.primary.opacity(layer.opacity))  // ✅ Changed to .fill for solid trapezium
            }
        }
        .onAppear {
            setupLayers()
        }
        .onChange(of: trigger) { oldValue, newValue in
            if !oldValue && newValue {
                setupLayers()
                
                progress = 0
                shrink = 0
                layerScales = layers.map { _ in 0.3 }
                
                for (index, layer) in layers.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + layer.delay) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            progress = 1
                            layerScales[index] = layer.scale
                        }
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeIn(duration: 0.5)) {
                        shrink = 1
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    trigger = false
                }
            }
        }
    }
    
    private func setupLayers() {
        layers = [
            // Background layers (smaller, dimmer)
            RayLayer(seed: Int.random(in: 0...10_000), scale: 0.7, opacity: 0.3, delay: 0.00),
            RayLayer(seed: Int.random(in: 0...10_000), scale: 0.85, opacity: 0.5, delay: 0.01),
            
            // Mid layers
            RayLayer(seed: Int.random(in: 0...10_000), scale: 1.0, opacity: 0.7, delay: 0.02),
            RayLayer(seed: Int.random(in: 0...10_000), scale: 1.15, opacity: 0.8, delay: 0.03),
            
            // Foreground layers (bigger, brighter)
            RayLayer(seed: Int.random(in: 0...10_000), scale: 1.5, opacity: 0.9, delay: 0.04),
            RayLayer(seed: Int.random(in: 0...10_000), scale: 1.8, opacity: 1.0, delay: 0.05),
            
            // Hero rays (very prominent)
            RayLayer(seed: Int.random(in: 0...10_000), scale: 2.2, opacity: 1.0, delay: 0.06),
        ]
        layerScales = layers.map { $0.scale }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var burst = false
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                
                SunburstView(trigger: $burst)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                VStack {
                    Text("10")
                        .font(.system(size: 120, weight: .bold))
                        .foregroundColor(.white)
                    Button("Trigger Burst") {
                        burst = true
                    }
                    .padding(.top, 40)
                }
            }
        }
    }
    
    return PreviewWrapper()
}
