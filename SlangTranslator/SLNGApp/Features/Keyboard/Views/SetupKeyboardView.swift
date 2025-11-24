//
//  SetupKeyboardView.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 04/11/25.
//

import SwiftUI
import Lottie
internal import Combine

struct SetupKeyboardView: View {
    @ObservedObject var viewModel: KeyboardStatusViewModel
    @AppStorage("hasOpenKeyboardSetting", store: UserDefaults.shared) private var hasOpenKeyboardSetting = false
    var onReturnFromSettings: () -> Void
    var isOnboarding: Bool = false
    var onSkipOnboarding: (() -> Void)? = nil
    @Environment(\.colorScheme) var colorScheme
    @State private var hasTriggeredReturn = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var subscriptions: Set<AnyCancellable> = []

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 8){
                HStack
                {
                    Text("Setup Keyboard")
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                        .foregroundStyle(AppColor.Button.primary)
                    Spacer()
                }
                Text("Follow these quick steps to enable real-time translation in any app.")
                    .font(.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
                
                LottieView(animation: .named(colorScheme == .light ? "keyboard-setup-light" : "keyboard-setup-dark"))
                    .looping()
                    .accessibilityHidden(true)
                
                Spacer()
                
            }
            .padding(.top, 20)
            .padding(.horizontal,20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack {
                Spacer()
                VStack(spacing: 10){
                    PrimaryButton(
                        buttonColor: AppColor.Button.onboarding,
                        textColor: .onboardingTextPrimary,
                        accessibilityLabel: "Add SLNG keyboard",
                        accessibilityHint: "Opens iOS Settings to enable the keyboard",
                        action: {
                            openKeyboardSettings()
                        }
                    ) {
                        Text("Add Keyboard")
                            .padding(.vertical, 18)
                            .font(Font.body.bold())
                            .frame(maxWidth: .infinity, minHeight: 60)
                    }
                    .accessibilityIdentifier("SetupKeyboardView.AddKeyboard")
                    
                    Text("This will open IOS system settings")
                        .font(.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 150)
                .padding(.horizontal)
                .padding(.bottom, 50)
                .background(AppColor.Background.secondary)
            }
        }
        .toolbar {
            if isOnboarding {
                ToolbarItem(placement: .topBarTrailing) {
                    Button{
                        onSkipOnboarding?()
                    } label: {
                        HStack {
                            Text("Skip")
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
        }
        .background(AppColor.Background.secondary)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            checkKeyboardStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkKeyboardStatus()
        }
        .onAppear(){
            checkKeyboardStatus()
            setupReactiveSinks()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkKeyboardStatus()
            }
        }
    }
    
    private func checkKeyboardStatus() {
        viewModel.updateKeyboardStatus()
        DispatchQueue.main.async {
            let didOpenSettings = UserDefaults.standard.bool(forKey: "didOpenKeyboardSettings")
            let hasSetup = UserDefaults.shared.bool(forKey: "hasSetupKeyboard")
            if (viewModel.isFullAccessEnabled || didOpenSettings || hasSetup) && !hasTriggeredReturn {
                hasOpenKeyboardSetting = true
                hasTriggeredReturn = true
                onReturnFromSettings()
                UserDefaults.standard.set(false, forKey: "didOpenKeyboardSettings")
            }
        }
    }
    
    private func setupReactiveSinks() {
        NotificationCenter.default.publisher(
            for: UserDefaults.didChangeNotification,
            object: UserDefaults.shared
        )
        .receive(on: RunLoop.main)
        .sink { _ in
            checkKeyboardStatus()
        }
        .store(in: &subscriptions)

        viewModel.$isFullAccessEnabled
            .receive(on: RunLoop.main)
            .sink { fullAccess in
                if fullAccess && !hasTriggeredReturn {
                    hasOpenKeyboardSetting = true
                    hasTriggeredReturn = true
                    onReturnFromSettings()
                }
            }
            .store(in: &subscriptions)

        NotificationCenter.default.publisher(
            for: UIApplication.willEnterForegroundNotification
        )
        .receive(on: RunLoop.main)
        .sink { _ in
            let didOpenSettings = UserDefaults.standard.bool(forKey: "didOpenKeyboardSettings")
            let hasSetup = UserDefaults.shared.bool(forKey: "hasSetupKeyboard")
            if (didOpenSettings || hasSetup) && !hasTriggeredReturn {
                hasOpenKeyboardSetting = true
                hasTriggeredReturn = true
                onReturnFromSettings()
                UserDefaults.standard.set(false, forKey: "didOpenKeyboardSettings")
            }
        }
        .store(in: &subscriptions)

        NotificationCenter.default.publisher(
            for: UIApplication.didBecomeActiveNotification
        )
        .receive(on: RunLoop.main)
        .sink { _ in
            let didOpenSettings = UserDefaults.standard.bool(forKey: "didOpenKeyboardSettings")
            let hasSetup = UserDefaults.shared.bool(forKey: "hasSetupKeyboard")
            if (didOpenSettings || hasSetup) && !hasTriggeredReturn {
                hasOpenKeyboardSetting = true
                hasTriggeredReturn = true
                onReturnFromSettings()
                UserDefaults.standard.set(false, forKey: "didOpenKeyboardSettings")
            }
        }
        .store(in: &subscriptions)
    }
    
    private func openKeyboardSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { _ in
                UserDefaults.standard.set(true, forKey: "didOpenKeyboardSettings")
            }
        }
    }
}
