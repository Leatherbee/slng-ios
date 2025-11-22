//
//  DictionaryDetail.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 28/10/25.
//
import SwiftUI
import Foundation
import FirebaseAnalytics
import AVFoundation
struct DictionaryDetail: View {
    @Environment(PopupManager.self) private var popupManager
    @State private var slangData: SlangModel?
    @State private var variants: [SlangModel] = []
    @State private var selectedVariantIndex: Int = 0
    @State private var canonicalForm: String = ""
    @State private var showCloseButton: Bool = false
    @StateObject private var viewModel = DictionaryDetailViewModel()
    @State private var showInfoSheet: Bool = false
    @State private var sheetHeight: CGFloat = 300
    @State private var showBurst = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var scale: CGFloat = 1
    @State private var opacity: CGFloat = 1

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        ZStack{
            VStack(spacing: 64){
                if !showCloseButton{
                    Spacer()
                        .frame(width: 43, height: 43)
                }
                if showCloseButton {
                    HStack{
                        Spacer()
                        Button {
                            Analytics.logEvent("dictionary_detail_close", parameters: ["source": "popup"])
                            popupManager.isPresented.toggle()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(AppColor.Button.Text.primary)
                        }
                        .frame(width: 43, height: 43)
                        .background(
                            Group {
                                if #available(iOS 26, *) {
                                    Circle()
                                        .glassEffect(.regular.tint(AppColor.Button.primary).interactive())
                                } else {
                                    Circle()
                                        .fill(AppColor.Button.primary)
                                }
                            }
                        )
                        .clipShape(.circle)
                        .transition(.opacity)
                    }
                    .frame(maxWidth: .infinity)
                }
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.Background.secondary)
            GeometryReader { screenGeo in
                SunburstView(trigger: $showBurst)
                    .allowsHitTesting(false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .position(x: screenGeo.size.width / 2,
                              y: screenGeo.size.height / 2 - 150)
            }
            .zIndex(2)
            DictionaryDetailView(
                slangData: slangData,
                variants: variants,
                selectedVariantIndex: $selectedVariantIndex,
                viewModel: viewModel
            )
            .scaleEffect(scale)
            .opacity(opacity)
            .onChange(of: showBurst) {
                if showBurst { 
                    scale = 0.8
                    opacity = 0.8

                    withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                        scale = 1
                        opacity = 1
                    }
                }
            }
            VStack{
                 Spacer()
                     .frame(height: 450)
                 VStack(spacing:64){
                     VStack(spacing: 16){
                         Text("Word Variations")
                             .font(.system(size: 18, design: .serif))
                             .multilineTextAlignment(.center)
                             .foregroundColor(AppColor.Text.primary)
                         WrapLayoutCenter(spacing: 8, lineSpacing: 8) {
                             ForEach(Array(variants.prefix(6).enumerated()), id: \.offset) { idx, v in
                                 similiarButton(title: v.slang, isActive: idx == selectedVariantIndex) {
                                     Analytics.logEvent("dictionary_similar_selected", parameters: ["index": idx])
                                     showBurst = false
                                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                                         showBurst = true
                                         playBurstSound()
                                         selectedVariantIndex = idx
                                     }
                                   
                                 }
                             }
                         }
                     }
                 }
             }
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              Spacer()
        }
        
        .onAppear() {
            self.slangData = popupManager.getSlangData()
            self.variants = popupManager.getVariants()
            self.canonicalForm = popupManager.getCanonicalForm() ?? ""
            if !variants.isEmpty { selectedVariantIndex = 0 }
            Analytics.logEvent("dictionary_detail_open", parameters: [
                "variants_count": variants.count
            ])
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeIn(duration: 0.3)) {
                    self.showCloseButton = true
                }
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            NavigationView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Context")
                            .font(.system(size: 17, design: .serif))
                            .bold().italic()
                            .foregroundColor(AppColor.Text.primary)
                        let current = variants.indices.contains(selectedVariantIndex) ? variants[selectedVariantIndex] : slangData
                        Text(current?.contextEN ?? "")
                            .font(.system(size: 17, design: .serif))
                            .foregroundColor(AppColor.Text.primary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Example")
                            .font(.system(size: 17, design: .serif))
                            .bold().italic()
                            .foregroundColor(AppColor.Text.primary)
                        Text("""
                        "\(variants.indices.contains(selectedVariantIndex) ? variants[selectedVariantIndex].exampleEN : slangData?.exampleEN ?? "")"
                        "\(variants.indices.contains(selectedVariantIndex) ? variants[selectedVariantIndex].exampleID : slangData?.exampleID ?? "")"
                        """)
                        .font(.system(size: 17, design: .serif))
                        .foregroundColor(AppColor.Text.primary)
                        .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 0)
                }
                .padding()
                .navigationTitle("Explanation")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        if #available(iOS 26.0, *) {
                            Button {
                                showInfoSheet.toggle()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 17))
                            }
                            .glassEffect(.regular.tint(AppColor.Text.primary).interactive())
                            .frame(width: 44, height: 44)
                            .foregroundColor(AppColor.Text.primary.opacity(0.6))
                            .clipShape(.circle)
                        } else {
                            Button {
                                showInfoSheet.toggle()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 17))
                            }
                            .frame(width: 44, height: 44)
                            .foregroundColor(AppColor.Text.primary.opacity(0.6))
                            .clipShape(.circle)
                        }
                      
                    }
                }
            }
            .presentationDetents([.fraction(0.4)])
            .presentationDragIndicator(.visible)
        }
    }
    
    private struct similiarButton:  View {
        let title: String
        let isActive: Bool
        let onTap: () -> Void

        var body: some View {
            Button { onTap() } label: {
                Text(title)
                    .font(.system(size: 16, design: .serif))
                    .foregroundColor(isActive ? AppColor.Button.Text.primary : AppColor.Text.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isActive ? AppColor.Button.primary : .clear)
            .cornerRadius(37)
            .overlay {
                RoundedRectangle(cornerRadius: 37)
                    .inset(by: 0.5)
                    .stroke(
                        AppColor.Button.primary
                    )
            }
        }
    }
    
    private func playBurstSound() {
        guard let url = Bundle.main.url(forResource: "whoosh", withExtension: "mp3") else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 0.9
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            fatalError()
        }
    }

}

struct WrapLayoutCenter: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8
    
    struct Line {
        var items: [(LayoutSubview, CGSize)] = []
        var totalWidth: CGFloat = 0
        var maxHeight: CGFloat = 0
    }
    
    func makeLines(subviews: LayoutSubviews, maxWidth: CGFloat) -> [Line] {
        var lines: [Line] = []
        var current = Line()
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            
            if current.totalWidth + size.width > maxWidth && !current.items.isEmpty {
                lines.append(current)
                current = Line()
            }
            
            current.items.append((view, size))
            current.totalWidth += size.width + spacing
            current.maxHeight = max(current.maxHeight, size.height)
        }
        
        if !current.items.isEmpty {
            lines.append(current)
        }
        
        return lines
    }
    
    func sizeThatFits(proposal: ProposedViewSize,
                      subviews: LayoutSubviews,
                      cache: inout ()) -> CGSize {
        
        let maxWidth = proposal.width ?? .infinity
        let lines = makeLines(subviews: subviews, maxWidth: maxWidth)
        
        let height = lines.reduce(0) { $0 + $1.maxHeight }
        + CGFloat(max(0, lines.count - 1)) * lineSpacing
        
        return CGSize(width: maxWidth, height: height)
    }
    
    func placeSubviews(in bounds: CGRect,
                       proposal: ProposedViewSize,
                       subviews: LayoutSubviews,
                       cache: inout ()) {
        
        let maxWidth = bounds.width
        let lines = makeLines(subviews: subviews, maxWidth: maxWidth)
        
        var y = bounds.minY
        
        for line in lines {
            let totalWidth = line.totalWidth - spacing
            let startX = bounds.minX + (maxWidth - totalWidth) / 2  // CENTER
            
            var x = startX
            
            for (view, size) in line.items {
                view.place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: size.width, height: size.height)
                )
                
                x += size.width + spacing
            }
            
            y += line.maxHeight + lineSpacing
        }
    }
}







//
struct DictionaryDetail_Previews: PreviewProvider {
    static var previews: some View {
        let mockPopupManager = PopupManager()
        
        // Setup mock data
        let mockSlang = SlangModel(
            id: UUID(),
            canonicalForm: "Pergi",
            canonicalPronunciation: "per-gi",
            slang: "Cabut",
            pronunciation: "ca-but",
            translationID: "Pergi sekarang",
            translationEN: "Leave now",
            contextID: "Digunakan ketika mengajak seseorang untuk pergi dari tempat tersebut.",
            contextEN: "Used when asking someone to leave the place.",
            exampleID: "Bro, cabut sekarang yuk!",
            exampleEN: "Bro, let's leave now!",
            sentiment: .neutral
        )
        mockPopupManager.setSlangData(mockSlang)
        
        let mockVariants = [
            SlangModel(
                id: UUID(),
                canonicalForm: "Pergi",
                canonicalPronunciation: "per-gi",
                slang: "Cabut",
                pronunciation: "ca-but",
                translationID: "Pergi sekarang",
                translationEN: "Leave now",
                contextID: "Dipakai ketika ingin pergi.",
                contextEN: "Used when someone wants to leave.",
                exampleID: "Cabut yuk!",
                exampleEN: "Let's leave!",
                sentiment: .neutral
            ),
            SlangModel(
                id: UUID(),
                canonicalForm: "Pergi",
                canonicalPronunciation: "per-gi",
                slang: "Angkat kaki",
                pronunciation: "ang-kat ka-ki",
                translationID: "Pergi dari tempat",
                translationEN: "Leave the place",
                contextID: "Dalam konteks santai.",
                contextEN: "Used in casual context.",
                exampleID: "Yuk angkat kaki dari sini!",
                exampleEN: "Let's get out of here!",
                sentiment: .neutral
            )
        ]
        mockPopupManager.setVariants(mockVariants)
        
        // Simulate popup manager with data
        mockPopupManager.isPresented = true
        
        return DictionaryDetail()
            .environment(mockPopupManager)
            .onAppear {
                // Set the mock data after view appears
                // In real implementation, you'd set this through PopupManager's methods
            }
    }
}
