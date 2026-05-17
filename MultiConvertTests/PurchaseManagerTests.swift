import Testing
import Foundation
@testable import MultiConvert

@Suite("Purchase Manager")
struct PurchaseManagerTests {

    @Test func isPremiumDefaultsFalse() {
        UserDefaults.standard.removeObject(forKey: "isPremium")
        let manager = PurchaseManager()
        // With no entitlements and no cached value, isPremium must be false.
        #expect(!manager.isPremium)
    }

    @Test func freeKeypadCapsAt72() {
        // On iPhone 16 Pro Max (430pt): computed = (430-32-36)/4 = 90.5 → capped at 72
        let d = NumericKeypad.buttonDiameter(screenWidth: 430, isPremium: false)
        #expect(d == 72)
    }

    @Test func premiumKeypadCapsAt84() {
        // On iPhone 16 Pro Max (430pt): computed = 90.5 → capped at 84
        let d = NumericKeypad.buttonDiameter(screenWidth: 430, isPremium: true)
        #expect(d == 84)
    }
}
