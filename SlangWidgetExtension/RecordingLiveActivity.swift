//
//  RecordingLiveActivity.swift
//  SlangWidgetExtension
//
//  Live Activity widget for speech-to-text recording.
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Activity Attributes (Shared with main app)

struct RecordingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var isRecording: Bool
        var isTranscribing: Bool
        var elapsedSeconds: Int
        var audioLevel: Float
        var previewText: String?
        var hasError: Bool

        static var initial: ContentState {
            ContentState(
                isRecording: true,
                isTranscribing: false,
                elapsedSeconds: 0,
                audioLevel: -160,
                previewText: nil,
                hasError: false
            )
        }
    }

    let startTime: Date
}

// MARK: - Recording Live Activity Widget

@available(iOS 16.2, *)
struct RecordingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecordingActivityAttributes.self) { context in
            // Lock Screen / Banner View
            RecordingLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded View
                DynamicIslandExpandedRegion(.leading) {
                    RecordingExpandedLeading(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    RecordingExpandedTrailing(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    RecordingExpandedBottom(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    RecordingExpandedCenter(context: context)
                }
            } compactLeading: {
                RecordingCompactLeading(context: context)
            } compactTrailing: {
                RecordingCompactTrailing(context: context)
            } minimal: {
                RecordingMinimal(context: context)
            }
        }
    }
}

// MARK: - Lock Screen View

@available(iOS 16.2, *)
struct RecordingLockScreenView: View {
    let context: ActivityViewContext<RecordingActivityAttributes>

    private let darkBackground = Color(red: 0.1, green: 0.1, blue: 0.1)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row
            HStack {
                // App icon
                ZStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 28, height: 28)

                    Image(systemName: context.state.isTranscribing ? "waveform" : "waveform.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
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

                // Timer
                Text(formattedTime)
                    .font(.system(size: 24, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }

            // Preview text or audio visualization
            if let preview = context.state.previewText {
                Text(preview)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            } else if context.state.isRecording {
                AudioLevelBar(level: context.state.audioLevel, isActive: true)
                    .frame(height: 6)
            }

            // Deep link
            HStack {
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
            return "Error"
        } else if context.state.isTranscribing {
            return "Transcribing..."
        } else if context.state.isRecording {
            return "Listening..."
        } else {
            return "Done"
        }
    }

    private var formattedTime: String {
        let minutes = context.state.elapsedSeconds / 60
        let seconds = context.state.elapsedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Audio Level Bar

@available(iOS 16.2, *)
struct AudioLevelBar: View {
    let level: Float
    let isActive: Bool

    private var normalizedLevel: CGFloat {
        let minDb: Float = -60
        let maxDb: Float = 0
        let clampedLevel = max(minDb, min(maxDb, level))
        return CGFloat((clampedLevel - minDb) / (maxDb - minDb))
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<24, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(barColor(for: index))
                        .frame(width: (geometry.size.width - 46) / 24)
                }
            }
        }
    }

    private func barColor(for index: Int) -> Color {
        let threshold = Int(normalizedLevel * 24)
        if index < threshold && isActive {
            return .orange
        }
        return Color.white.opacity(0.2)
    }
}

// MARK: - Dynamic Island Views

@available(iOS 16.2, *)
struct RecordingCompactLeading: View {
    let context: ActivityViewContext<RecordingActivityAttributes>

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.orange)
                .frame(width: 24, height: 24)

            Image(systemName: context.state.isTranscribing ? "waveform" : "waveform.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

@available(iOS 16.2, *)
struct RecordingCompactTrailing: View {
    let context: ActivityViewContext<RecordingActivityAttributes>

    var body: some View {
        Text(formattedTime)
            .font(.system(size: 14, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(.white)
    }

    private var formattedTime: String {
        let minutes = context.state.elapsedSeconds / 60
        let seconds = context.state.elapsedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

@available(iOS 16.2, *)
struct RecordingMinimal: View {
    let context: ActivityViewContext<RecordingActivityAttributes>

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.orange)
                .frame(width: 14, height: 14)

            if context.state.isRecording {
                Image(systemName: "waveform")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
}

@available(iOS 16.2, *)
struct RecordingExpandedLeading: View {
    let context: ActivityViewContext<RecordingActivityAttributes>

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 28, height: 28)

                Image(systemName: context.state.isTranscribing ? "waveform" : "waveform.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text("SLNG")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

@available(iOS 16.2, *)
struct RecordingExpandedTrailing: View {
    let context: ActivityViewContext<RecordingActivityAttributes>

    var body: some View {
        Text(formattedTime)
            .font(.system(size: 22, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(.white)
    }

    private var formattedTime: String {
        let minutes = context.state.elapsedSeconds / 60
        let seconds = context.state.elapsedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

@available(iOS 16.2, *)
struct RecordingExpandedCenter: View {
    let context: ActivityViewContext<RecordingActivityAttributes>

    var body: some View {
        Text(statusText)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
    }

    private var statusText: String {
        if context.state.hasError {
            return "Error"
        } else if context.state.isTranscribing {
            return "Transcribing..."
        } else {
            return "Listening..."
        }
    }
}

@available(iOS 16.2, *)
struct RecordingExpandedBottom: View {
    let context: ActivityViewContext<RecordingActivityAttributes>

    var body: some View {
        VStack(spacing: 8) {
            if let preview = context.state.previewText {
                Text(preview)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if context.state.isRecording {
                AudioLevelBar(level: context.state.audioLevel, isActive: true)
                    .frame(height: 6)
            }

            Link(destination: URL(string: "slng://translate")!) {
                Text("Open in SLNG")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.orange)
            }
        }
    }
}

// MARK: - Preview

@available(iOS 16.2, *)
#Preview("Recording", as: .content, using: RecordingActivityAttributes(startTime: .now)) {
    RecordingLiveActivity()
} contentStates: {
    RecordingActivityAttributes.ContentState(
        isRecording: true,
        isTranscribing: false,
        elapsedSeconds: 5,
        audioLevel: -30,
        previewText: nil,
        hasError: false
    )
    RecordingActivityAttributes.ContentState(
        isRecording: false,
        isTranscribing: true,
        elapsedSeconds: 8,
        audioLevel: -160,
        previewText: nil,
        hasError: false
    )
    RecordingActivityAttributes.ContentState(
        isRecording: false,
        isTranscribing: false,
        elapsedSeconds: 10,
        audioLevel: -160,
        previewText: "gws bang semoga cepet sembuh",
        hasError: false
    )
}
