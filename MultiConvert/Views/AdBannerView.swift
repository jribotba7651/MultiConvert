import SwiftUI
import GoogleMobileAds

struct AdBannerView: View {
    #if DEBUG
    private let adUnitID = "ca-app-pub-3940256099942544/2934735716"
    #else
    private let adUnitID = "ca-app-pub-3258994800717071/4399651250"
    #endif

    private let bannerHeight: CGFloat = 50

    var body: some View {
        GeometryReader { geo in
            let adSize = inlineAdaptiveBanner(width: geo.size.width, maxHeight: bannerHeight)
            BannerRepresentable(adUnitID: adUnitID, adSize: adSize)
                .frame(width: geo.size.width, height: bannerHeight)
        }
        .frame(height: 50)
    }
}

private struct BannerRepresentable: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView()
        banner.adUnitID = adUnitID
        banner.adSize = adSize
        banner.delegate = context.coordinator
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {
        if banner.rootViewController == nil,
           let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            banner.rootViewController = root
            banner.load(Request())
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, BannerViewDelegate {
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("[AdBanner] Failed to load: \(error.localizedDescription)")
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("[AdBanner] Ad loaded, size: \(bannerView.adSize.size)")
        }
    }
}
