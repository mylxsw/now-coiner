import Foundation
import StoreKit
import NowCoinerCore

struct AppStorePurchaseValidator: PurchaseValidating {
    func validatePurchase() async -> AppLicenseState {
        let environment = ProcessInfo.processInfo.environment

        if environment["NOWCOINER_FORCE_TRIAL"] == "1" {
            return .trial
        }

        if environment["NOWCOINER_FORCE_PURCHASED"] == "1" {
            return .purchased
        }

        #if DEBUG
        return .purchased
        #else
        do {
            let verification = try await AppTransaction.shared
            switch verification {
            case .verified:
                return .purchased
            case .unverified:
                return .trial
            }
        } catch {
            return .trial
        }
        #endif
    }
}
