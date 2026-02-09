import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public var launchAtLogin: Bool
    public var globalShortcut: String
    public var vsCurrency: String
    public var menuBarDisplayStyle: MenuBarStyle
    public var menuBarCoinDisplayMode: MenuBarCoinDisplayMode
    public var menuBarUsePriceColor: Bool
    public var appearanceMode: AppearanceMode
    public var appLanguage: AppLanguage
    public var priceColorScheme: PriceColorScheme
    public var refreshInterval: RefreshInterval
    public var defaultDataSource: DataSource
    public var defaultExchange: Exchange

    public init(
        launchAtLogin: Bool = false,
        globalShortcut: String = "⌘⇧C",
        vsCurrency: String = "usd",
        menuBarDisplayStyle: MenuBarStyle = .symbolAndPrice,
        menuBarCoinDisplayMode: MenuBarCoinDisplayMode = .text,
        menuBarUsePriceColor: Bool = false,
        appearanceMode: AppearanceMode = .system,
        appLanguage: AppLanguage = .followSystem,
        priceColorScheme: PriceColorScheme = .greenUpRedDown,
        refreshInterval: RefreshInterval = .realtime,
        defaultDataSource: DataSource = .coinGecko,
        defaultExchange: Exchange = .binance
    ) {
        self.launchAtLogin = launchAtLogin
        self.globalShortcut = globalShortcut
        self.vsCurrency = vsCurrency
        self.menuBarDisplayStyle = menuBarDisplayStyle
        self.menuBarCoinDisplayMode = menuBarCoinDisplayMode
        self.menuBarUsePriceColor = menuBarUsePriceColor
        self.appearanceMode = appearanceMode
        self.appLanguage = appLanguage
        self.priceColorScheme = priceColorScheme
        self.refreshInterval = refreshInterval
        self.defaultDataSource = defaultDataSource
        self.defaultExchange = defaultExchange
    }

    public static let `default` = AppSettings()

    enum CodingKeys: String, CodingKey {
        case launchAtLogin
        case globalShortcut
        case vsCurrency
        case menuBarDisplayStyle
        case menuBarCoinDisplayMode
        case menuBarUsePriceColor
        case appearanceMode
        case appLanguage
        case priceColorScheme
        case refreshInterval
        case defaultDataSource
        case defaultExchange
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        globalShortcut = try container.decodeIfPresent(String.self, forKey: .globalShortcut) ?? "⌘⇧C"
        vsCurrency = try container.decodeIfPresent(String.self, forKey: .vsCurrency) ?? "usd"
        menuBarDisplayStyle = try container.decodeIfPresent(MenuBarStyle.self, forKey: .menuBarDisplayStyle) ?? .symbolAndPrice
        menuBarCoinDisplayMode = try container.decodeIfPresent(MenuBarCoinDisplayMode.self, forKey: .menuBarCoinDisplayMode) ?? .text
        menuBarUsePriceColor = try container.decodeIfPresent(Bool.self, forKey: .menuBarUsePriceColor) ?? false
        appearanceMode = try container.decodeIfPresent(AppearanceMode.self, forKey: .appearanceMode) ?? .system
        appLanguage = try container.decodeIfPresent(AppLanguage.self, forKey: .appLanguage) ?? .followSystem
        priceColorScheme = try container.decodeIfPresent(PriceColorScheme.self, forKey: .priceColorScheme) ?? .greenUpRedDown
        refreshInterval = try container.decodeIfPresent(RefreshInterval.self, forKey: .refreshInterval) ?? .realtime
        defaultDataSource = try container.decodeIfPresent(DataSource.self, forKey: .defaultDataSource) ?? .coinGecko
        defaultExchange = try container.decodeIfPresent(Exchange.self, forKey: .defaultExchange) ?? .binance
    }
}

public enum MenuBarStyle: String, Codable, CaseIterable, Sendable {
    case priceOnly
    case symbolAndPrice
    case symbolAndChange
    case full

    public var title: String {
        switch self {
        case .priceOnly: return "仅价格"
        case .symbolAndPrice: return "符号 + 价格"
        case .symbolAndChange: return "符号 + 涨跌幅"
        case .full: return "完整"
        }
    }
}

public enum MenuBarCoinDisplayMode: String, Codable, CaseIterable, Sendable {
    case text
    case icon

    public var title: String {
        switch self {
        case .text: return "文字"
        case .icon: return "图标"
        }
    }
}

public enum AppearanceMode: String, Codable, CaseIterable, Sendable {
    case light
    case dark
    case system
}

public enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case followSystem
    case zhHans
    case en
}

public enum PriceColorScheme: String, Codable, CaseIterable, Sendable {
    case greenUpRedDown
    case redUpGreenDown
}

public enum RefreshInterval: String, Codable, CaseIterable, Sendable {
    case realtime
    case seconds10
    case seconds30
    case minute1
    case minutes5

    public var seconds: TimeInterval {
        switch self {
        case .realtime: return 1
        case .seconds10: return 10
        case .seconds30: return 30
        case .minute1: return 60
        case .minutes5: return 300
        }
    }
}

public enum DataSource: String, Codable, CaseIterable, Sendable {
    case coinGecko
    case binance
}

public enum Exchange: String, Codable, CaseIterable, Sendable {
    case binance
    case coinbase
    case okx

    public var tradingViewPrefix: String {
        switch self {
        case .binance: return "BINANCE"
        case .coinbase: return "COINBASE"
        case .okx: return "OKX"
        }
    }
}
