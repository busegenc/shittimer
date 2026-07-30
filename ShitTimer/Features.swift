import Foundation

/// Sürüme göre açılıp kapanan özellikler.
enum Features {
    /// Tema paketi (uygulama içi satın alma).
    ///
    /// `false` iken: yalnızca ücretsiz Klasik tema görünür, tema seçici ve
    /// satın alma ekranı hiç gösterilmez. App Store'da Paid Applications
    /// sözleşmesi aktifleşene kadar bu şekilde yayınlanıyor — böylece
    /// kullanıcı çalışmayan bir satın almayla karşılaşmıyor.
    ///
    /// Banka/vergi tarafı tamamlanınca `true` yap, build numarasını artır
    /// ve yeni sürümü gönder; ürün App Store Connect'te zaten hazır.
    static let themePackEnabled = false
}
