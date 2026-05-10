import SwiftUI

@main
struct MyVoyageApp: App {
    @State private var showSplash = true

    init() {
        // Vergrößere den globalen URLCache, damit AsyncImage-Downloads
        // (Wikipedia-Coverfotos) persistent auf Disk gecached werden.
        // Default ist nur ~20 MB Disk; mit 500 MB passen die Hero-Bilder
        // aller Reisen problemlos rein und sind beim nächsten App-Start
        // sofort verfügbar.
        URLCache.shared = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 500 * 1024 * 1024,
            directory: nil
        )
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView(isPresented: $showSplash)
                        .transition(.opacity)
                } else {
                    ContentView()
                        .transition(.opacity)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
