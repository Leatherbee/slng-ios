//
//  ExpandedTranslationView.swift
//  SlangTranslator
//
//  Created by Cynthia Yapiter on 05/11/25.
//

import SwiftUI
import UIKit
import FirebaseAnalytics

struct ExpandedTranslationView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let text: String
    let onClose: () -> Void
    
    private let rotationChangePublisher = NotificationCenter.default
        .publisher(for: UIDevice.orientationDidChangeNotification)
    @State private var isOrientationLocked = false

    @Environment(\.dismiss) private var dismiss
    
    var fullScreen: Bool = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(AppColor.Background.secondary)
                .ignoresSafeArea()

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
                Analytics.logEvent("expanded_translation_close", parameters: nil)
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
            changeOrientation(to: .landscape)
        }
        .onDisappear {
            changeOrientation(to: .portrait)
        }
//        .onReceive(rotationChangePublisher) { _ in
//            if isOrientationLocked {
//                changeOrientation(to: .portrait)
//            }
//        }
    }
    
    func changeOrientation(to orientation: UIInterfaceOrientationMask) {
        // tell the app to change the orientation
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        
        if fullScreen {
            if #available(iOS 16.0, *) {
                windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
            } else {
                // Fallback on earlier versions
            }
        } else {
            if #available(iOS 16.0, *) {
                windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            } else {
                // Fallback on earlier versions
            }
        }
    }
}
//
//private enum OrientationLock {
//    static func set(_ mask: UIInterfaceOrientationMask, rotateTo fallback: UIInterfaceOrientation) {
//        DispatchQueue.main.async {
//            apply(mask: mask, fallback: fallback)
//        }
//    }
//    
//    private static func apply(mask: UIInterfaceOrientationMask, fallback: UIInterfaceOrientation) {
//        if #available(iOS 16.0, *) {
//            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
//                let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: mask)
//                try? scene.requestGeometryUpdate(prefs)
//            }
//        } else {
//            UIDevice.current.setValue(fallback.rawValue, forKey: "orientation")
//            UIViewController.attemptRotationToDeviceOrientation()
//        }
//    }
//}
