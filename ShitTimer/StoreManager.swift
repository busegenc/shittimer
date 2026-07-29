import Foundation
import StoreKit

/// Tema paketi satın alma yönetimi (tek seferlik, non-consumable).
/// Ücretsiz tema: Klasik. Arcade ve Pastel satın alma ile açılır.
@MainActor
final class StoreManager: ObservableObject {
    static let themePackID = "com.busegenc.shittimer.themepack"

    @Published private(set) var product: Product?
    @Published private(set) var isPremium: Bool
    @Published var isWorking = false
    @Published var errorMessage: String?

    private let defaults = UserDefaults.standard
    private let premiumKey = "premiumUnlocked"
    private var updatesTask: Task<Void, Never>?

    init() {
        isPremium = defaults.bool(forKey: premiumKey)
        #if DEBUG
        if CommandLine.arguments.contains("--premium") { unlock() }
        if CommandLine.arguments.contains("--no-premium") {
            isPremium = false
            defaults.set(false, forKey: premiumKey)
        }
        #endif

        // Başka cihazda yapılan/askıda kalan satın almalar
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }

        Task {
            await loadProduct()
            await refreshEntitlements()
        }
    }

    /// Mağazadan gelen yerelleştirilmiş fiyat
    var priceText: String {
        if let product { return product.displayPrice }
        #if DEBUG
        // Simülatörde StoreKit yapılandırması yokken arayüzü görebilmek için
        return MessagePool.isTurkish ? "₺79,99" : "$1.99"
        #else
        return "—"
        #endif
    }

    func loadProduct() async {
        product = try? await Product.products(for: [Self.themePackID]).first
    }

    func purchase() async {
        guard let product else {
            #if DEBUG
            // StoreKit yapılandırması olmayan ortamda akışı denemek için
            unlock()
            #else
            errorMessage = L10n.storeUnavailable
            #endif
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                await handle(verification)
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// App Store kuralı: non-consumable ürünlerde geri yükleme şart
    func restore() async {
        isWorking = true
        defer { isWorking = false }
        try? await AppStore.sync()
        await refreshEntitlements()
        if !isPremium { errorMessage = L10n.nothingToRestore }
    }

    private func refreshEntitlements() async {
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            if transaction.productID == Self.themePackID, transaction.revocationDate == nil {
                unlock()
                return
            }
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == Self.themePackID, transaction.revocationDate == nil {
            unlock()
        }
        await transaction.finish()
    }

    private func unlock() {
        isPremium = true
        defaults.set(true, forKey: premiumKey)
    }
}
