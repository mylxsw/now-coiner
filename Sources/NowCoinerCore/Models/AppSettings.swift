import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public var launchAtLogin: Bool
    public var globalShortcut: String
    public var vsCurrency: String
    public var menuBarDisplayStyle: MenuBarStyle
    public var appearanceMode: AppearanceMode
    public var priceColorScheme: PriceColorScheme
    public var refreshInterval: RefreshInterval
    public var defaultDataSource: DataSource
    public var defaultExchange: Exchange

    public init(
        launchAtLogin: Bool = false,
        globalShortcut: String = "⌘⇧C",
        vsCurrency: String = "usd",
        menuBarDisplayStyle: MenuBarStyle = .symbolAndPrice,
        appearanceMode: AppearanceMode = .system,
        priceColorScheme: PriceColorScheme = .greenUpRedDown,
        refreshInterval: RefreshInterval = .realtime,
        defaultDataSource: DataSource = .coinGecko,
        defaultExchange: Exchange = .binance
    ) {
        self.launchAtLogin = launchAtLogin
        self.globalShortcut = globalShortcut
        self.vsCurrency = vsCurrency
        self.menuBarDisplayStyle = menuBarDisplayStyle
        self.appearanceMode = appearanceMode
        self.priceColorScheme = priceColorScheme
        self.refreshInterval = refreshInterval
        self.defaultDataSource = defaultDataSource
        self.defaultExchange = defaultExchange
    }

    public static let `default` = AppSettings()
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

public enum AppearanceMode: String, Codable, CaseIterable, Sendable {
    case light
    case dark
    case system
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
