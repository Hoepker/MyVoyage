import SwiftUI

@main
struct MyVoyageApp: App {
    @State private var showSplash = true

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
