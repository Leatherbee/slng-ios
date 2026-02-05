//
//  SlangWidgetBundle.swift
//  SlangWidgetExtension
//
//  Widget bundle entry point for SLNG app widgets.
//

import WidgetKit
import SwiftUI

@main
struct SlangWidgetBundle: WidgetBundle {
    var body: some Widget {
        SlangWidget()

        if #available(iOS 16.2, *) {
            RecordingLiveActivity()
            TranslationLiveActivity()
        }
    }
}
