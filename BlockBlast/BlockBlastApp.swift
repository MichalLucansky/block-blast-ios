import SwiftUI
import AdMobKit

@main
struct BlockBlastApp: App {
    init() {
        // Start the Google Mobile Ads SDK and preload the first rewarded ad.
        AdService.shared.start(config: AdConfig.test)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
