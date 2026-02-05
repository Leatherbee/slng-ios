//
//  SlangWidget.swift
//  SlangWidgetExtension
//
//  Widget that displays a random slang word, updated every hour.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct SlangEntry: TimelineEntry {
    let date: Date
    let slang: String
    let translation: String
    let context: String
}

// MARK: - Timeline Provider

struct SlangTimelineProvider: TimelineProvider {
    private let appGroupID = "group.prammmoe.SLNG"
    private let shownSlangKey = "widget.shownSlangIndices"

    func placeholder(in context: Context) -> SlangEntry {
        SlangEntry(
            date: Date(),
            slang: "wkwk",
            translation: "ekspresi tertawa",
            context: "Digunakan untuk menunjukkan tertawa dalam chat"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SlangEntry) -> Void) {
        let entry = getRandomSlangEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SlangEntry>) -> Void) {
        let currentDate = Date()
        let entry = getRandomSlangEntry()

        // Schedule next update in 1 hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    // MARK: - Private Methods

    private func getRandomSlangEntry() -> SlangEntry {
        let slangs = loadSlangsFromJSON()

        guard !slangs.isEmpty else {
            return SlangEntry(
                date: Date(),
                slang: "SLNG",
                translation: "Slang Translator",
                context: "Buka app untuk melihat slang"
            )
        }

        // Get shown indices from UserDefaults
        let defaults = UserDefaults(suiteName: appGroupID)
        var shownIndices = defaults?.array(forKey: shownSlangKey) as? [Int] ?? []

        // Find indices that haven't been shown
        let allIndices = Set(0..<slangs.count)
        let shownSet = Set(shownIndices)
        var availableIndices = Array(allIndices.subtracting(shownSet))

        // If all shown, reset
        if availableIndices.isEmpty {
            shownIndices = []
            availableIndices = Array(allIndices)
        }

        // Pick random from available
        let randomIndex = availableIndices.randomElement() ?? 0
        let slang = slangs[randomIndex]

        // Mark as shown
        shownIndices.append(randomIndex)
        defaults?.set(shownIndices, forKey: shownSlangKey)

        return SlangEntry(
            date: Date(),
            slang: slang.slang,
            translation: slang.translationID,
            context: slang.contextID
        )
    }

    private func loadSlangsFromJSON() -> [WidgetSlangData] {
        // Try loading from shared container first
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            let jsonURL = containerURL.appendingPathComponent("slng_widget_data.json")
            if let data = try? Data(contentsOf: jsonURL),
               let slangs = try? JSONDecoder().decode([WidgetSlangData].self, from: data) {
                return slangs
            }
        }

        // Fallback to bundled JSON
        guard let url = Bundle.main.url(forResource: "slng_data_v1.2", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return []
        }

        do {
            let groups = try JSONDecoder().decode([WidgetSlangGroup].self, from: data)
            var allSlangs: [WidgetSlangData] = []
            for group in groups {
                for variant in group.variants {
                    allSlangs.append(WidgetSlangData(
                        slang: variant.slang,
                        translationID: variant.translationID,
                        contextID: variant.contextID
                    ))
                }
            }
            return allSlangs
        } catch {
            return []
        }
    }
}

// MARK: - Data Models for Widget

struct WidgetSlangGroup: Codable {
    let canonicalForm: String
    let variants: [WidgetSlangVariant]
}

struct WidgetSlangVariant: Codable {
    let slang: String
    let translationID: String
    let contextID: String
}

struct WidgetSlangData: Codable {
    let slang: String
    let translationID: String
    let contextID: String
}

// MARK: - Widget View

struct SlangWidgetEntryView: View {
    var entry: SlangEntry
    @Environment(\.widgetFamily) var family

    /// Deep link URL to open slang detail
    private var deepLinkURL: URL {
        let encodedSlang = entry.slang.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? entry.slang
        return URL(string: "slng://dictionary?slang=\(encodedSlang)")!
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallWidget
            case .systemMedium:
                mediumWidget
            case .systemLarge:
                largeWidget
            default:
                smallWidget
            }
        }
        .widgetURL(deepLinkURL)
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SLNG")
                .font(.system(size: 10, weight: .medium, design: .serif))
                .foregroundStyle(.secondary)

            Text(entry.slang)
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Spacer()

            Text(entry.translation)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var mediumWidget: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("SLNG")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(entry.slang)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(entry.translation)
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(.primary)
                .lineLimit(1)

            if !entry.context.isEmpty {
                Text(entry.context)
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SLNG")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Slang of the Hour")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(entry.slang)
                .font(.system(size: 42, weight: .bold, design: .serif))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.5)

            Text(entry.translation)
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(.primary)
                .lineLimit(2)

            Spacer()

            if !entry.context.isEmpty {
                Text(entry.context)
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Configuration

struct SlangWidget: Widget {
    let kind: String = "SlangWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SlangTimelineProvider()) { entry in
            SlangWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Slang of the Hour")
        .description("Pelajari slang Indonesia baru setiap jam.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    SlangWidget()
} timeline: {
    SlangEntry(date: .now, slang: "wkwk", translation: "ekspresi tertawa", context: "Digunakan untuk menunjukkan tertawa")
}

#Preview(as: .systemMedium) {
    SlangWidget()
} timeline: {
    SlangEntry(date: .now, slang: "gws", translation: "get well soon", context: "Ucapan semoga lekas sembuh")
}

#Preview(as: .systemLarge) {
    SlangWidget()
} timeline: {
    SlangEntry(date: .now, slang: "bestie", translation: "sahabat", context: "Panggilan untuk teman dekat atau sahabat")
}
