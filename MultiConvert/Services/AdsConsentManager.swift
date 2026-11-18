import AppTrackingTransparency
import GoogleMobileAds
import SwiftUI
import UserMessagingPlatform

/// Orders the ad-related consent steps required before any ad request:
///
/// 1. Google UMP consent info update (GDPR / US state privacy messages).
/// 2. UMP consent form, only if UMP says it's required for this user.
/// 3. App Tracking Transparency prompt.
/// 4. `MobileAds.shared.start`, only if UMP says ads may be requested.
///
/// Premium (ad-free) users skip the whole flow: no consent form, no ATT
/// prompt, and the Mobile Ads SDK is never started.
@MainActor
@Observable
final class AdsConsentManager {
    /// True once the Mobile Ads SDK has been started and ads may be loaded.
    private(set) var canShowAds = false
    /// True when UMP requires a "Privacy choices" entry point in Settings.
    private(set) var isPrivacyOptionsRequired = false

    private var isGathering = false
    private var adsStarted = false

    func startIfNeeded(isPremium: Bool) async {
        guard !isPremium, !isGathering, !adsStarted else { return }
        isGathering = true
        defer { isGathering = false }

        let consent = ConsentInformation.shared

        do {
            try await consent.requestConsentInfoUpdate(with: RequestParameters())
        } catch {
            log("Consent info update failed: \(error.localizedDescription)")
        }

        do {
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
        } catch {
            log("Consent form failed: \(error.localizedDescription)")
        }
        updatePrivacyOptionsStatus()

        await requestTrackingAuthorizationIfNeeded()

        // canRequestAds also covers a consent obtained in a previous session
        // when this session's info update failed (e.g. offline).
        if consent.canRequestAds {
            startAds()
        }
    }

    /// Re-opens the UMP privacy options form from Settings.
    func presentPrivacyOptions() async {
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
        } catch {
            log("Privacy options form failed: \(error.localizedDescription)")
        }
        updatePrivacyOptionsStatus()
        if ConsentInformation.shared.canRequestAds {
            startAds()
        }
    }

    // MARK: - Private

    private func updatePrivacyOptionsStatus() {
        isPrivacyOptionsRequired =
            ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    private func startAds() {
        guard !adsStarted else { return }
        adsStarted = true
        MobileAds.shared.start(completionHandler: nil)
        canShowAds = true
    }

    private func requestTrackingAuthorizationIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        // The ATT prompt is silently dropped unless the app is active, so wait
        // for that (up to ~5 s), then give the UI a moment to settle.
        for _ in 0..<20 where UIApplication.shared.applicationState != .active {
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
        try? await Task.sleep(nanoseconds: 500_000_000)
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    private func log(_ message: String) {
        #if DEBUG
        print("[Consent] \(message)")
        #endif
    }
}
