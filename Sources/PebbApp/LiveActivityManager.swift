import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif
import WidgetKit

/// Starts / updates / ends Pebb Live Activities (Dynamic Island + Lock Screen)
/// and keeps the App Group store fresh so the home/lock-screen widgets update.
@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private let appGroup = "group.dev.pebb.app"

    #if canImport(ActivityKit)
    private var current: Activity<PebbActivityAttributes>?
    #endif

    // MARK: - Chat "thinking" activity
    func startThinking() {
        #if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        endAll()
        let attrs = PebbActivityAttributes(kind: "chat")
        let state = PebbActivityAttributes.ContentState(
            phase: "thinking", title: "Pebb is thinking…", detail: "", progress: 0
        )
        current = try? Activity.request(
            attributes: attrs,
            content: .init(state: state, staleDate: Date().addingTimeInterval(60))
        )
        #endif
    }

    func finishThinking(preview: String) {
        #if canImport(ActivityKit)
        Task {
            let state = PebbActivityAttributes.ContentState(
                phase: "done", title: "Pebb replied", detail: String(preview.prefix(80)), progress: 1
            )
            await current?.update(.init(state: state, staleDate: nil))
            await current?.end(nil, dismissalPolicy: .after(Date().addingTimeInterval(3)))
            current = nil
        }
        #endif
    }

    // MARK: - App "building" activity
    func startBuilding(appName: String) {
        #if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        endAll()
        let attrs = PebbActivityAttributes(kind: "build")
        let state = PebbActivityAttributes.ContentState(
            phase: "building", title: "Building your app…", detail: appName, progress: 0.05
        )
        current = try? Activity.request(
            attributes: attrs,
            content: .init(state: state, staleDate: nil)
        )
        #endif
    }

    func updateBuild(progress: Double, detail: String) {
        #if canImport(ActivityKit)
        Task {
            let state = PebbActivityAttributes.ContentState(
                phase: "building", title: "Building your app…", detail: detail, progress: min(0.97, progress)
            )
            await current?.update(.init(state: state, staleDate: nil))
        }
        #endif
    }

    func finishBuilding(detail: String) {
        #if canImport(ActivityKit)
        Task {
            let state = PebbActivityAttributes.ContentState(
                phase: "done", title: "Your app is ready 🎉", detail: detail, progress: 1
            )
            await current?.update(.init(state: state, staleDate: nil))
            await current?.end(nil, dismissalPolicy: .after(Date().addingTimeInterval(5)))
            current = nil
        }
        #endif
    }

    func endAll() {
        #if canImport(ActivityKit)
        for activity in Activity<PebbActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
        current = nil
        #endif
    }

    // MARK: - Widget data sync
    func updateWidgetData(lastMessage: String? = nil, headline: String? = nil,
                          category: String? = nil, source: String? = nil) {
        let d = UserDefaults(suiteName: appGroup)
        if let lastMessage { d?.set(lastMessage, forKey: "widget_last_message") }
        if let headline { d?.set(headline, forKey: "widget_news_headline") }
        if let category { d?.set(category, forKey: "widget_news_category") }
        if let source { d?.set(source, forKey: "widget_news_source") }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
