import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Shared between the app (which starts/updates activities) and the widget
/// extension (which renders them on the Lock Screen + Dynamic Island).
#if canImport(ActivityKit)
struct PebbActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// "thinking", "building", "done"
        var phase: String
        /// Headline shown in the live activity, e.g. "Pebb is thinking…"
        var title: String
        /// Optional secondary line (partial reply / app name being built)
        var detail: String
        /// 0...1 progress for build activities (ignored when thinking)
        var progress: Double
    }

    /// What kind of activity this is: "chat" or "build"
    var kind: String
}
#endif
