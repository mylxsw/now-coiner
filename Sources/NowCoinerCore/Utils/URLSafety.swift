import Foundation

public enum URLSafety {
    private static let allowedIconHostSuffix = ".coingecko.com"
    private static let allowedIconHosts: Set<String> = [
        "assets.coingecko.com",
        "coin-images.coingecko.com"
    ]

    public static func validatedExternalWebURL(from raw: String?) -> URL? {
        guard let raw, !raw.isEmpty else { return nil }
        guard let components = URLComponents(string: raw) else { return nil }
        guard components.scheme?.lowercased() == "https" else { return nil }
        guard let host = components.host, !host.isEmpty else { return nil }
        guard components.user == nil, components.password == nil else { return nil }
        return components.url
    }

    public static func validatedIconURL(from raw: String?) -> URL? {
        guard let url = validatedExternalWebURL(from: raw),
              let host = url.host?.lowercased() else {
            return nil
        }

        if allowedIconHosts.contains(host) {
            return url
        }
        if host.hasSuffix(allowedIconHostSuffix), host != String(allowedIconHostSuffix.dropFirst()) {
            return url
        }

        return nil
    }
}
