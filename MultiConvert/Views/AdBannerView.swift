// TODO: Ad integration — before App Store submission:
// 1. Add the Google Mobile Ads SDK via SPM:
//    https://github.com/googleads/swift-package-manager-google-mobile-ads
// 2. Replace the stub body below with the real GADBannerView implementation.
// 3. Replace the test ad unit ID with your live banner unit ID from AdMob.
// 4. Call GADMobileAds.sharedInstance().start() in MultiConvertApp.init().
//
// Test ad unit ID (safe for development):
//   ca-app-pub-3940256099942544/2934735716
//
// The stub renders an empty 50pt strip so layout is already reserved — no
// layout changes needed when the real SDK is dropped in.

import SwiftUI

struct AdBannerView: View {
    var body: some View {
        // STUB — replace with real banner once Google Mobile Ads SDK is added.
        Color.clear
            .frame(height: 50)
    }
}
