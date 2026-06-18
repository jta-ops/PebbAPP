import SwiftUI
import WidgetKit

// Shared storage written by the app (App Group).
private let appGroup = "group.dev.pebb.app"
private func sharedDefaults() -> UserDefaults? { UserDefaults(suiteName: appGroup) }

// MARK: - News Widget

struct NewsEntry: TimelineEntry {
    let date: Date
    let headline: String
    let category: String
    let source: String
}

struct NewsProvider: TimelineProvider {
    func placeholder(in context: Context) -> NewsEntry {
        NewsEntry(date: Date(), headline: "Today's top story, delivered by Pebb", category: "Tech", source: "Pebb News")
    }
    func getSnapshot(in context: Context, completion: @escaping (NewsEntry) -> Void) {
        completion(currentEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<NewsEntry>) -> Void) {
        let entry = currentEntry()
        // refresh in ~30 min
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
    private func currentEntry() -> NewsEntry {
        let d = sharedDefaults()
        return NewsEntry(
            date: Date(),
            headline: d?.string(forKey: "widget_news_headline") ?? "Open Pebb to load today's news",
            category: d?.string(forKey: "widget_news_category") ?? "News",
            source: d?.string(forKey: "widget_news_source") ?? "Pebb News"
        )
    }
}

struct PebbNewsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PebbNewsWidget", provider: NewsProvider()) { entry in
            NewsWidgetView(entry: entry)
        }
        .configurationDisplayName("Pebb News")
        .description("Today's top headline.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

struct NewsWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: NewsEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("📰 \(entry.headline)")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.category.uppercased()).font(.system(size: 10, weight: .bold))
                Text(entry.headline).font(.system(size: 13, weight: .semibold)).lineLimit(2)
            }
        default:
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [Color(hex: "1A1828"), Color(hex: "0B0A12")], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image("PebbLogo").resizable().scaledToFill()
                            .frame(width: 18, height: 18)
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        Text(entry.category.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color(hex: "9B8FE8"))
                    }
                    Spacer()
                    Text(entry.headline)
                        .font(.system(size: family == .systemMedium ? 16 : 14, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(family == .systemMedium ? 3 : 4)
                    Text(entry.source)
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "6E6A8A"))
                }
                .padding(14)
            }
        }
    }
}

// MARK: - Latest Message Widget

struct MessageEntry: TimelineEntry {
    let date: Date
    let message: String
}

struct MessageProvider: TimelineProvider {
    func placeholder(in context: Context) -> MessageEntry {
        MessageEntry(date: Date(), message: "hey! what's on your mind? 💜")
    }
    func getSnapshot(in context: Context, completion: @escaping (MessageEntry) -> Void) { completion(currentEntry()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<MessageEntry>) -> Void) {
        completion(Timeline(entries: [currentEntry()], policy: .after(Date().addingTimeInterval(900))))
    }
    private func currentEntry() -> MessageEntry {
        MessageEntry(date: Date(), message: sharedDefaults()?.string(forKey: "widget_last_message") ?? "Tap to chat with Pebb")
    }
}

struct PebbMessageWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PebbMessageWidget", provider: MessageProvider()) { entry in
            MessageWidgetView(entry: entry)
        }
        .configurationDisplayName("Latest from Pebb")
        .description("Your most recent message from Pebb.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct MessageWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: MessageEntry
    var body: some View {
        if family == .accessoryRectangular {
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "message.fill").font(.system(size: 11))
                Text(entry.message).font(.system(size: 12)).lineLimit(3)
            }
        } else {
            ZStack {
                LinearGradient(colors: [Color(hex: "1E1C30"), Color(hex: "0B0A12")], startPoint: .topLeading, endPoint: .bottomTrailing)
                VStack(alignment: .leading, spacing: 8) {
                    Image("PebbLogo").resizable().scaledToFill()
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    Text(entry.message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "EDEBF7"))
                        .lineLimit(4)
                    Spacer()
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
