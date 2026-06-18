import SwiftUI
import WidgetKit

@main
struct PebbWidgetBundle: WidgetBundle {
    var body: some Widget {
        PebbNewsWidget()
        PebbMessageWidget()
        if #available(iOS 16.1, *) {
            PebbLiveActivity()
        }
    }
}
