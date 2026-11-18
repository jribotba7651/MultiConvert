import StoreKit
import SwiftUI

@MainActor
@Observable
final class PurchaseManager {

    private(set) var isPremium: Bool
    private(set) var isPurchasing: Bool = false
    private(set) var isRestoring: Bool = false
    private(set) var products: [Product] = []
    private(set) var isLoadingProducts = false
    private(set) var productsError: String?
    /// User-facing result of the last purchase/restore (success, pending,
    /// nothing to restore). Cleared when a new action starts.
    private(set) var statusMessage: String?

    // Written once in init, only cancelled in deinit.
    @ObservationIgnored nonisolated(unsafe) private var updatesTask: Task<Void, Never>?
    private static let productID = "com.jibaroenlaluna.multiconvert.removeads"
    private static let premiumKey = "isPremium"

    init() {
        // Seed from cache so UI is correct before the StoreKit check completes.
        isPremium = UserDefaults.standard.bool(forKey: Self.premiumKey)
        updatesTask = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                await self?.handle(result)
            }
        }
        Task { await refreshEntitlements() }
    }

    deinit { updatesTask?.cancel() }

    // MARK: - Public API

    func loadProducts() async {
        guard products.isEmpty, !isLoadingProducts else { return }
        isLoadingProducts = true
        productsError = nil
        defer { isLoadingProducts = false }

        // Retry a few times: a fresh launch can race the network, and an empty
        // result (no products configured / agreements not active yet) is worth
        // surfacing instead of leaving the UI stuck silently.
        for attempt in 1...3 {
            do {
                let fetched = try await Product.products(for: [Self.productID])
                products = fetched
                productsError = fetched.isEmpty
                    ? "Store unavailable. Check your connection or try again later."
                    : nil
                if !fetched.isEmpty { return }
            } catch {
                #if DEBUG
                print("[Purchase] loadProducts attempt \(attempt) failed: \(error.localizedDescription)")
                #endif
                productsError = error.localizedDescription
            }
            if attempt < 3 {
                try? await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
            }
        }
    }

    func purchase() async throws {
        guard let product = products.first else { return }
        isPurchasing = true
        statusMessage = nil
        defer { isPurchasing = false }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let tx = try verified(verification)
            await tx.finish()
            setIsPremium(true)
            statusMessage = "Thank you! Ads have been removed."
        case .pending:
            // Ask to Buy / SCA: Transaction.updates delivers it once approved.
            statusMessage = "Your purchase is pending approval. Ads will be removed as soon as it's approved."
        case .userCancelled:
            break
        @unknown default:
            break
        }
    }

    func restorePurchases() async {
        guard !isRestoring else { return }
        isRestoring = true
        statusMessage = nil
        defer { isRestoring = false }

        var syncError: Error?
        do {
            try await AppStore.sync()
        } catch StoreKitError.userCancelled {
            return
        } catch {
            syncError = error
        }

        await refreshEntitlements()

        if isPremium {
            statusMessage = "Purchase restored. Ads are removed."
        } else if let syncError {
            statusMessage = "Couldn't reach the App Store: \(syncError.localizedDescription)"
        } else {
            statusMessage = "No previous purchase found for this Apple ID."
        }
    }

    /// Re-reads current entitlements from StoreKit and updates `isPremium`.
    func refreshEntitlements() async {
        var found = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.productID == Self.productID,
               tx.revocationDate == nil {
                found = true
            }
        }
        setIsPremium(found)
    }

    // MARK: - Private

    private func handle(_ result: VerificationResult<StoreKit.Transaction>) async {
        if case .verified(let tx) = result {
            await tx.finish()
            await refreshEntitlements()
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.verificationFailed
        case .verified(let v): return v
        }
    }

    private func setIsPremium(_ value: Bool) {
        isPremium = value
        UserDefaults.standard.set(value, forKey: Self.premiumKey)
    }
}

enum StoreError: LocalizedError {
    case verificationFailed
    var errorDescription: String? { "Purchase verification failed. Please try again." }
}
