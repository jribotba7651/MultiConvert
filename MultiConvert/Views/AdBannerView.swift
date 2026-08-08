import SwiftUI
import GoogleMobileAds

struct AdBannerView: View {
    #if DEBUG
    private let adUnitID = "ca-app-pub-3940256099942544/2934735716"
    #else
    private let adUnitID = "ca-app-pub-3258994800717071/4399651250"
    #endif

    private let bannerHeight: CGFloat = 50

    // Reserve vertical space only once an ad actually fills. A brand-new AdMob
    // unit (or a no-fill response) would otherwise leave a permanent empty 50pt
    // band under the keypad; collapsing to 0 keeps the layout tight until real
    // creative arrives, then animates in when it does.
    @State private var isLoaded = false

    var body: some View {
        GeometryReader { geo in
            let adSize = inlineAdaptiveBanner(width: geo.size.width, maxHeight: bannerHeight)
            BannerRepresentable(adUnitID: adUnitID, adSize: adSize, isLoaded: $isLoaded)
                .frame(width: geo.size.width, height: bannerHeight)
        }
        .frame(height: isLoaded ? bannerHeight : 0)
        .clipped()
        .animation(.easeInOut(duration: 0.2), value: isLoaded)
    }
}

private struct BannerRepresentable: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize
    @Binding var isLoaded: Bool

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

    func makeCoordinator() -> Coordinator { Coordinator(isLoaded: $isLoaded) }

    final class Coordinator: NSObject, BannerViewDelegate {
        @Binding private var isLoaded: Bool

        init(isLoaded: Binding<Bool>) {
            _isLoaded = isLoaded
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("[AdBanner] Failed to load: \(error.localizedDescription)")
            isLoaded = false
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("[AdBanner] Ad loaded, size: \(bannerView.adSize.size)")
            isLoaded = true
        }
    }
}
