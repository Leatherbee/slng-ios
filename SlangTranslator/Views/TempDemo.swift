import SwiftUI
import CoreGraphics

// MARK: - Shape dengan seed random
struct VariableSunburstShape: Shape {
    var seed: Int
    var progress: CGFloat
    var shrink: CGFloat
    var scale: CGFloat // Parameter baru untuk depth
    
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
        /// Kalau mau ngurangin density dari rays-nya bisa ngatur di density: ini
        let clusters = [
            (start: 0.0, end: 0.3, density: 2),
            (start: 0.3, end: 0.55, density: 1),
            (start: 0.55, end: 0.7, density: 2),
            (start: 0.7, end: 1.0, density: 1)
        ]
        
        for cluster in clusters {
            for _ in 0..<cluster.density {
                let angle = (cluster.start + drand48() * (cluster.end - cluster.start)) * 2 * .pi
                
                /// Radius titik spawn rays awal. Kalau mau ubah pakai variable yang `baseStart` ini.
                let baseStart = CGFloat(60 + drand48() * 80) * scale
                let baseLength = CGFloat(drand48()) * 0.8 * maxLength + maxLength * 0.6
                
                let finalLength = baseLength * progress
                let startRadius = baseStart + (finalLength * shrink)
                if finalLength <= startRadius { continue }
                
                let start = CGPoint(
                    x: center.x + cos(angle) * startRadius,
                    y: center.y + sin(angle) * startRadius
                )
                let end = CGPoint(
                    x: center.x + cos(angle) * finalLength,
                    y: center.y + sin(angle) * finalLength
                )
                
                path.move(to: start)
                path.addLine(to: end)
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
    let lineWidth: CGFloat
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
                .stroke(Color.primary.opacity(layer.opacity),
                        style: StrokeStyle(lineWidth: layer.lineWidth,
                                           lineCap: .round))
            }
        }
        .onAppear {
            setupLayers()
        }
        /// Setup durasi animasi (shrink dll) di sini
        .onChange(of: trigger) { oldValue, newValue in
            // Hanya trigger ketika berubah dari false ke true
            if !oldValue && newValue {
                // Generate new seeds
                setupLayers()
                
                // Reset animation states
                progress = 0
                shrink = 0
                layerScales = layers.map { _ in 0.3 }
                
                // Animate each layer with staggered timing for depth effect
                for (index, layer) in layers.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + layer.delay) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            progress = 1
                            layerScales[index] = layer.scale
                        }
                    }
                }
                
                // Shrink effect
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeIn(duration: 0.5)) {
                        shrink = 1
                    }
                }
                
                // Reset trigger setelah animasi selesai
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    trigger = false
                }
            }
        }
    }
    
    private func setupLayers() {
        layers = [
            // Background layers (smaller, dimmer)
            RayLayer(seed: Int.random(in: 0...10_000), scale: 0.7, lineWidth: 1.5, opacity: 0.3, delay: 0.00),
            RayLayer(seed: Int.random(in: 0...10_000), scale: 0.85, lineWidth: 2, opacity: 0.5, delay: 0.01),
            
            // Mid layers
            RayLayer(seed: Int.random(in: 0...10_000), scale: 1.0, lineWidth: 2.5, opacity: 0.7, delay: 0.02),
            RayLayer(seed: Int.random(in: 0...10_000), scale: 1.15, lineWidth: 3, opacity: 0.8, delay: 0.03),
            
            // Foreground layers (bigger, brighter)
            RayLayer(seed: Int.random(in: 0...10_000), scale: 1.5, lineWidth: 4, opacity: 0.9, delay: 0.04),
            RayLayer(seed: Int.random(in: 0...10_000), scale: 1.8, lineWidth: 5, opacity: 1.0, delay: 0.05),
            
            // Hero rays (very prominent) - LEBIH BESAR!
            RayLayer(seed: Int.random(in: 0...10_000), scale: 2.2, lineWidth: 6, opacity: 1.0, delay: 0.06),
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
