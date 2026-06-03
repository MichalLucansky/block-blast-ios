import Foundation
import UIKit
import GoogleMobileAds

/// Central owner of the Google Mobile Ads lifecycle: SDK start-up, the banner
/// ad unit id, and loading/presenting the rewarded ("bonus life") ad.
///
/// All identifiers below are Google's public **test** ad units. Swap them (and
/// `GADApplicationIdentifier` in Info.plist) for real ids before shipping.
@MainActor
final class AdManager: NSObject, ObservableObject {
    /// Test banner ad unit (iOS).
    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    /// Test rewarded ad unit (iOS).
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"

    /// `true` once a rewarded ad has loaded and is ready to present.
    @Published private(set) var isRewardedAdReady = false

    private var rewardedAd: RewardedAd?
    private var isStarted = false

    /// Starts the SDK (idempotent) and preloads the first rewarded ad.
    func start() {
        guard !isStarted else { return }
        isStarted = true
        MobileAds.shared.start { [weak self] _ in
            self?.loadRewardedAd()
        }
    }

    /// Loads (or reloads) a rewarded ad so it is ready for the next request.
    func loadRewardedAd() {
        RewardedAd.load(with: Self.rewardedAdUnitID, request: Request()) { [weak self] ad, error in
            guard let self else { return }
            if let error {
                print("AdManager: failed to load rewarded ad — \(error.localizedDescription)")
                self.rewardedAd = nil
                self.isRewardedAdReady = false
                return
            }
            ad?.fullScreenContentDelegate = self
            self.rewardedAd = ad
            self.isRewardedAdReady = ad != nil
        }
    }

    /// Presents the rewarded ad. `onReward` fires only if the user earns the
    /// reward (i.e. watches enough of the video). The next ad is preloaded
    /// automatically afterwards. If no ad is ready, `onReward` is not called.
    func showRewardedAd(onReward: @escaping () -> Void) {
        guard let rewardedAd, let root = Self.rootViewController else {
            loadRewardedAd()
            return
        }
        isRewardedAdReady = false
        rewardedAd.present(from: root) {
            onReward()
        }
    }

    /// The key window's root view controller, used to anchor banners and
    /// present full-screen ads.
    static var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}

// MARK: - FullScreenContentDelegate

extension AdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        rewardedAd = nil
        loadRewardedAd()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("AdManager: rewarded ad failed to present — \(error.localizedDescription)")
        rewardedAd = nil
        loadRewardedAd()
    }
}
