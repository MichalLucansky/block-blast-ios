import SwiftUI
import AdMobKit

/// AdMob banner wrapped for SwiftUI, sized to the standard 320x50 format so it
/// can sit in a normal layout flow.
struct BannerAdView: View {
    var body: some View {
        AdMobKit.BannerAdView()
            .frame(width: 320, height: 50)
    }
}

#Preview {
    BannerAdView()
}
