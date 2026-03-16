import Foundation

public enum AppLicenseState: Equatable, Sendable {
    case checking
    case purchased
    case trial
}

public protocol PurchaseValidating: Sendable {
    func validatePurchase() async -> AppLicenseState
}

public struct StaticPurchaseValidator: PurchaseValidating {
    public let state: AppLicenseState

    public init(state: AppLicenseState) {
        self.state = state
    }

    public func validatePurchase() async -> AppLicenseState {
        state
    }
}
