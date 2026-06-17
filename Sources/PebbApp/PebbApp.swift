import SwiftUI

struct PebbApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

@main
struct PebbAppMain {
    static func main() {
        PebbApp.main()
    }
}
