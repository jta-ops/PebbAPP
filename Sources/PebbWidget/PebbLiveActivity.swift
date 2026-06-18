import SwiftUI
import WidgetKit
import ActivityKit

@available(iOS 16.1, *)
struct PebbLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PebbActivityAttributes.self) { context in
            // Lock Screen / banner presentation
            LockScreenLiveView(context: context)
                .activityBackgroundTint(Color(hex: "0B0A12"))
                .activitySystemActionForegroundColor(Color(hex: "C4BBFF"))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    Image("PebbLogo")
                        .resizable().scaledToFill()
                        .frame(width: 34, height: 34)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.phase == "building" {
                        Text("\(Int(context.state.progress * 100))%")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "C4BBFF"))
                    } else if context.state.phase == "done" {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(hex: "34D399"))
                    } else {
                        ThinkingDots()
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                        if !context.state.detail.isEmpty {
                            Text(context.state.detail)
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "A09CBA"))
                                .lineLimit(2)
                        }
                        if context.state.phase == "building" {
                            ProgressView(value: context.state.progress)
                                .tint(Color(hex: "7C6FCD"))
                        }
                    }
                }
            } compactLeading: {
                Image("PebbLogo")
                    .resizable().scaledToFill()
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            } compactTrailing: {
                if context.state.phase == "building" {
                    Text("\(Int(context.state.progress * 100))%")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: "C4BBFF"))
                } else if context.state.phase == "done" {
                    Image(systemName: "checkmark").foregroundStyle(Color(hex: "34D399"))
                } else {
                    ThinkingDots()
                }
            } minimal: {
                Image("PebbLogo")
                    .resizable().scaledToFill()
                    .frame(width: 18, height: 18)
                    .clipShape(Circle())
            }
            .keylineTint(Color(hex: "7C6FCD"))
        }
    }
}

@available(iOS 16.1, *)
struct LockScreenLiveView: View {
    let context: ActivityViewContext<PebbActivityAttributes>
    var body: some View {
        HStack(spacing: 12) {
            Image("PebbLogo")
                .resizable().scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(context.state.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                if !context.state.detail.isEmpty {
                    Text(context.state.detail)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "A09CBA"))
                        .lineLimit(2)
                }
                if context.state.phase == "building" {
                    ProgressView(value: context.state.progress)
                        .tint(Color(hex: "7C6FCD"))
                        .padding(.top, 2)
                }
            }
            Spacer()
            if context.state.phase == "thinking" { ThinkingDots() }
            else if context.state.phase == "done" {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(hex: "34D399"))
            }
        }
        .padding(16)
    }
}

struct ThinkingDots: View {
    @State private var phase = 0
    let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color(hex: "9B8FE8"))
                    .frame(width: 6, height: 6)
                    .opacity(phase == i ? 1 : 0.3)
            }
        }
        .onReceive(timer) { _ in phase = (phase + 1) % 3 }
    }
}
