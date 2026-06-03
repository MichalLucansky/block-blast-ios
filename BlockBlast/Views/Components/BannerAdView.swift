import SwiftUI
import GoogleMobileAds

/// A fixed-size AdMob banner wrapped for SwiftUI, sized to the standard
/// 320x50 banner so it can sit in a normal layout flow.
struct BannerAdView: UIViewRepresentable {
    var adUnitID: String = AdManager.bannerAdUnitID

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = AdManager.rootViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}

#Preview {
    BannerAdView()
        .frame(width: 320, height: 50)
}
