//
//  ExpandedTranslationView.swift
//  SlangTranslator
//
//  Created by Cynthia Yapiter on 05/11/25.
//

import SwiftUI

struct ExpandedTranslationView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let text: String
    let onClose: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(AppColor.Background.secondary)
                .ignoresSafeArea()
            
            OrientationController(
                            orientation: .landscape,
                            fallback: .landscapeRight
                        )
                        .allowsHitTesting(false)
                        .frame(width: 0, height: 0)
            
            GeometryReader { geo in
                ScrollView(.vertical, showsIndicators: true){
                    VStack {
                        Spacer(minLength: geo.size.height / 4)
                        Text(text)
                            .font(.system(size: 64, weight: .bold, design: .serif))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 10)
                        Spacer(minLength: geo.size.height / 4)
                    }
                    .frame(minWidth: geo.size.width, minHeight: geo.size.height)
                }
                .frame(minWidth: geo.size.width, minHeight: geo.size.height)
            }
            
            Button {
                OrientationController(
                                    orientation: .portrait,
                                    fallback: .portrait
                                )
                                .lockImmediately()
                dismiss()
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.Background.primary)
                    .padding(20)
                    .background(
                        Group {
                            if #available(iOS 26, *) {
                                Circle()
                                    .glassEffect(.regular.tint(AppColor.Text.primary).interactive())
                                    .frame(width: 44, height: 44)
                            } else {
                                Circle()
                                    .fill(AppColor.Text.primary)
                                    .frame(width: 44, height: 44)
                            }
                        }
                    )
            }
            .accessibilityLabel("Close")
            .accessibilityIdentifier("ExpandedTranslationView.Close")
        }
        .onAppear {
            setOrientation(.landscape, fallback: .landscapeRight)
        }
    }
}

struct OrientationController: UIViewControllerRepresentable {
    let orientation: UIInterfaceOrientationMask
    let fallback: UIInterfaceOrientation

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        lock()
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    private func lock() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if #available(iOS 16.0, *) {
                let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientation)
                try? scene.requestGeometryUpdate(prefs)
            } else {
                UIDevice.current.setValue(fallback.rawValue, forKey: "orientation")
            }
        }
    }
}


extension ExpandedTranslationView {
    func setOrientation(_ mask: UIInterfaceOrientationMask, fallback: UIInterfaceOrientation) {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if #available(iOS 16.0, *) {
                let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: mask)
                try? scene.requestGeometryUpdate(prefs)
            } else {
                UIDevice.current.setValue(fallback.rawValue, forKey: "orientation")
            }
        } else {
            UIDevice.current.setValue(fallback.rawValue, forKey: "orientation")
        }
    }
}

extension OrientationController {
    func lockImmediately() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if #available(iOS 16.0, *) {
                let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientation)
                try? scene.requestGeometryUpdate(prefs)
            } else {
                UIDevice.current.setValue(fallback.rawValue, forKey: "orientation")
            }
        }
    }
}

