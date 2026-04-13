import Foundation

enum AppRoute: Hashable {
    case discovery
    case businessProfile(id: String)
    case vault
    case scanner
    case activity
}
