//
//  TranslationLiveActivity.swift
//  SlangWidgetExtension
//
//  Live Activity widget for translation processing.
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Activity Attributes (Shared with main app)

struct TranslationActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var isTranslating: Bool
        var inputPreview: String
        var resultPreview: String?
        var slangsCount: Int
        var hasError: Bool

        static func initial(inputPreview: String) -> ContentState {
            ContentState(
                isTranslating: true,
                inputPreview: String(inputPreview.prefix(50)),
                resultPreview: nil,
                slangsCount: 0,
                hasError: false
            )
        }
    }

    let startTime: Date
    let fullInputText: String
}

// MARK: - Translation Live Activity Widget

@available(iOS 16.2, *)
struct TranslationLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TranslationActivityAttributes.self) { context in
            // Lock Screen / Banner View
            TranslationLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded View
                DynamicIslandExpandedRegion(.leading) {
                    TranslationExpandedLeading(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TranslationExpandedTrailing(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    TranslationExpandedBottom(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    TranslationExpandedCenter(context: context)
                }
            } compactLeading: {
                TranslationCompactLeading(context: context)
            } compactTrailing: {
                TranslationCompactTrailing(context: context)
            } minimal: {
                TranslationMinimal(context: context)
            }
        }
    }
}

// MARK: - Lock Screen View

@available(iOS 16.2, *)
struct TranslationLockScreenView: View {
    let context: ActivityViewContext<TranslationActivityAttributes>

    private let darkBackground = Color(red: 0.1, green: 0.1, blue: 0.1)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack {
                // App icon
                ZStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 28, height: 28)

                    Image(systemName: "character.book.closed.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text("SLNG")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                // Status
                Text(statusText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)

                Spacer()

                // Loading indicator or checkmark
                if context.state.isTranslating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else if context.state.hasError {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.yellow)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                }
            }

            // Input text
            HStack(spacing: 8) {
                Text("Input:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))

                Text(context.state.inputPreview)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            }

            // Result text (if available)
            if let result = context.state.resultPreview {
                HStack(spacing: 8) {
                    Text("Result:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))

                    Text(result)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            }

            // Footer row
            HStack {
                if context.state.slangsCount > 0 {
                    Text("\(context.state.slangsCount) slang\(context.state.slangsCount > 1 ? "s" : "") detected")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.orange.opacity(0.9))
                }

                Spacer()

                Link(destination: URL(string: "slng://translate")!) {
                    Text("Open in SLNG")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(darkBackground)
    }

    private var statusText: String {
        if context.state.hasError {
            return "Failed"
        } else if context.state.isTranslating {
            return "Translating..."
        } else {
            return "Done"
        }
    }
}

// MARK: - Dynamic Island Views

@available(iOS 16.2, *)
struct TranslationCompactLeading: View {
    let context: ActivityViewContext<TranslationActivityAttributes>

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.orange)
                .frame(width: 24, height: 24)

            Image(systemName: "character.book.closed.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

@available(iOS 16.2, *)
struct TranslationCompactTrailing: View {
    let context: ActivityViewContext<TranslationActivityAttributes>

    var body: some View {
        if context.state.isTranslating {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.6)
        } else if context.state.hasError {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.yellow)
        } else {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.green)
        }
    }
}

@available(iOS 16.2, *)
struct TranslationMinimal: View {
    let context: ActivityViewContext<TranslationActivityAttributes>

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.orange)
                .frame(width: 14, height: 14)

            if !context.state.isTranslating && !context.state.hasError {
                Image(systemName: "checkmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
}

@available(iOS 16.2, *)
struct TranslationExpandedLeading: View {
    let context: ActivityViewContext<TranslationActivityAttributes>

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 28, height: 28)

                Image(systemName: "character.book.closed.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text("SLNG")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

@available(iOS 16.2, *)
struct TranslationExpandedTrailing: View {
    let context: ActivityViewContext<TranslationActivityAttributes>

    var body: some View {
        if context.state.isTranslating {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.8)
        } else if context.state.hasError {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(.yellow)
        } else {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(.green)
        }
    }
}

@available(iOS 16.2, *)
struct TranslationExpandedCenter: View {
    let context: ActivityViewContext<TranslationActivityAttributes>

    var body: some View {
        Text(statusText)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
    }

    private var statusText: String {
        if context.state.hasError {
            return "Failed"
        } else if context.state.isTranslating {
            return "Translating..."
        } else {
            return "Done"
        }
    }
}

@available(iOS 16.2, *)
struct TranslationExpandedBottom: View {
    let context: ActivityViewContext<TranslationActivityAttributes>

    var body: some View {
        VStack(spacing: 6) {
            // Input preview
            HStack(spacing: 6) {
                Text("Input:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))

                Text(context.state.inputPreview)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)

                Spacer()
            }

            // Result preview
            if let result = context.state.resultPreview {
                HStack(spacing: 6) {
                    Text("Result:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))

                    Text(result)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer()
                }
            }

            // Footer
            HStack {
                if context.state.slangsCount > 0 {
                    Text("\(context.state.slangsCount) slang\(context.state.slangsCount > 1 ? "s" : "")")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.orange.opacity(0.9))
                }

                Spacer()

                Link(destination: URL(string: "slng://translate")!) {
                    Text("Open in SLNG")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}

// MARK: - Preview

@available(iOS 16.2, *)
#Preview("Translation", as: .content, using: TranslationActivityAttributes(startTime: .now, fullInputText: "gws bang semoga cepet sembuh ya")) {
    TranslationLiveActivity()
} contentStates: {
    TranslationActivityAttributes.ContentState(
        isTranslating: true,
        inputPreview: "gws bang semoga cepet sembuh ya",
        resultPreview: nil,
        slangsCount: 0,
        hasError: false
    )
    TranslationActivityAttributes.ContentState(
        isTranslating: false,
        inputPreview: "gws bang semoga cepet sembuh ya",
        resultPreview: "Get well soon bro, hope you recover quickly",
        slangsCount: 2,
        hasError: false
    )
    TranslationActivityAttributes.ContentState(
        isTranslating: false,
        inputPreview: "gws bang semoga cepet sembuh ya",
        resultPreview: nil,
        slangsCount: 0,
        hasError: true
    )
}
