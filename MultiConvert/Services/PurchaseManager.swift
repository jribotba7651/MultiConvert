import StoreKit
import SwiftUI

@Observable
final class PurchaseManager {

    private(set) var isPremium: Bool
    private(set) var isPurchasing: Bool = false
    private(set) var products: [Product] = []

    private var updatesTask: Task<Void, Never>?
    private static let productID = "com.jibaroenlaluna.multiconvert.removeads"

    init() {
        // Seed from cache so UI is correct before the StoreKit check completes.
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        updatesTask = Task.detached(priority: .background) { [weak self] in
            for await result in StoreKit.Transaction.updates {
                await self?.handle(result)
            }
        }
        Task { await checkEntitlements() }
    }

    deinit { updatesTask?.cancel() }

    // MARK: - Public API

    func loadProducts() async {
        guard products.isEmpty else { return }
        do {
            products = try await Product.products(for: [Self.productID])
        } catch {
            // Non-fatal: button stays disabled if products can't be fetched.
        }
    }

    func purchase() async throws {
        guard let product = products.first else { return }
        await MainActor.run { isPurchasing = true }
        defer { Task { await MainActor.run { self.isPurchasing = false } } }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let tx = try verified(verification)
            await tx.finish()
            await setIsPremium(true)
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await checkEntitlements()
    }

    // MARK: - Private

    private func checkEntitlements() async {
        var found = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.productID == Self.productID,
               tx.revocationDate == nil {
                found = true
            }
        }
        await setIsPremium(found)
    }

    private func handle(_ result: VerificationResult<StoreKit.Transaction>) async {
        if case .verified(let tx) = result {
            await tx.finish()
            await checkEntitlements()
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.verificationFailed
        case .verified(let v): return v
        }
    }

    @MainActor
    private func setIsPremium(_ value: Bool) {
        isPremium = value
        UserDefaults.standard.set(value, forKey: "isPremium")
    }
}

enum StoreError: LocalizedError {
    case verificationFailed
    var errorDescription: String? { "Purchase verification failed. Please try again." }
}
