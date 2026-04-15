import Foundation

enum AppTab: Hashable {
    case discovery
    case vault
    case activity
    case settings
}

enum AppRoute: Hashable {
    case discovery
    case businessProfile(id: String)
    case vault
    case scanner
    case activity
}
