import Foundation

/// Supabase bağlantı bilgileri.
///
/// `anonKey` istemciye gömülmek için tasarlanmış **açık** anahtardır; gizli olan
/// `service_role` anahtarıdır ve uygulamaya asla konmaz. Verinin güvenliği
/// anahtarın gizliliğine değil, tablolardaki Row Level Security kurallarına dayanır.
///
/// Değerleri Supabase panelinde Project Settings → API bölümünden al.
enum SupabaseConfig {
    static let urlString = "https://lwvhvfzuttrukmclqhwo.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx3dmh2Znp1dHRydWttY2xxaHdvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc1MDc1MTgsImV4cCI6MjEwMzA4MzUxOH0.NYhik8pFvbon8ay6B_UD1RKi0d6wQc2fuFytZKAJ2IQ"

    static var isConfigured: Bool {
        !anonKey.isEmpty && !urlString.contains("YOUR-PROJECT")
    }

    static var baseURL: URL? { URL(string: urlString) }
}
