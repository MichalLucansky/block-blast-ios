import SwiftUI
import FactoryKit

@main
struct BlockBlastApp: App {
    @Injected(\.adManager) private var adManager: AdManager

    init() {
        // Start the Google Mobile Ads SDK and preload the first rewarded ad.
        adManager.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
