import Foundation
import StoreKit
import Observation
import CozyCore

/// Quản lý In-App Purchase thuần StoreKit 2 (Apple chính chủ, 0% phí bên thứ 3).
/// Tự tải mệnh giá tiền tệ thực tế trên Store từng nước (VND, USD, JPY, KRW, EUR...) và đồng bộ trạng thái mở khóa vào App Group.
@MainActor
@Observable
final class SubscriptionManager {
    private let repository: CozyRepository
    private(set) var productsByID: [String: Product] = [:]
    private(set) var isPurchasing = false
    private(set) var lastMessage: String?

    init(repository: CozyRepository) {
        self.repository = repository
    }

    var isPro: Bool {
        repository.snapshot().settings.isProUnlocked
    }

    /// Gọi khi mở app: tải danh sách gói từ App Store & kiểm tra quyền đã mua (`Transaction.currentEntitlements`).
    func refreshStoreState() async {
        await loadProducts()
        await verifyCurrentEntitlements()
    }

    func loadProducts() async {
        let ids = ProPlanKind.allCases.map(\.rawValue)
        guard let fetched = try? await Product.products(for: ids) else { return }
        var map: [String: Product] = [:]
        for p in fetched { map[p.id] = p }
        productsByID = map
    }

    func displayPrice(for plan: ProPlanKind) -> String {
        if let p = productsByID[plan.rawValue] {
            return p.displayPrice
        }
        return plan.fallbackDisplayPrice()
    }

    /// Thực hiện mua gói Yearly hoặc Lifetime qua StoreKit 2.
    @discardableResult
    func purchase(_ plan: ProPlanKind) async -> Bool {
        isPurchasing = true
        lastMessage = nil
        defer { isPurchasing = false }

        if productsByID[plan.rawValue] == nil {
            await loadProducts()
        }

        guard let product = productsByID[plan.rawValue] else {
            #if DEBUG
            // Cho phép test nhanh luồng mở khóa trên bản build Debug / Simulator chưa cấu hình App Store Connect.
            unlockProLocally()
            return true
            #else
            lastMessage = "App Store product is not configured yet (\(plan.rawValue))."
            return false
            #endif
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    unlockProLocally()
                    Haptics.success()
                    return true
                } else {
                    lastMessage = "Purchase verification failed."
                    return false
                }
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastMessage = error.localizedDescription
            return false
        }
    }

    /// Khôi phục giao dịch đã mua (Bắt buộc theo Apple App Store Review Guideline 3.1.2).
    func restorePurchases() async -> Bool {
        isPurchasing = true
        lastMessage = nil
        defer { isPurchasing = false }

        try? await AppStore.sync()
        await verifyCurrentEntitlements()
        let unlocked = repository.snapshot(reload: true).settings.isProUnlocked
        if unlocked { Haptics.success() }
        return unlocked
    }

    func verifyCurrentEntitlements() async {
        var hasValidPro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.revocationDate == nil,
               ProPlanKind.allCases.map(\.rawValue).contains(tx.productID) {
                hasValidPro = true
                break
            }
        }
        if hasValidPro {
            unlockProLocally()
        }
    }

    func unlockProLocally() {
        repository.updateSettings { $0.isProUnlocked = true }
        CozyShared.didChange()
    }
}
