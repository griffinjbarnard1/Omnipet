import Foundation

struct PetPass: Identifiable, Hashable {
    enum VaccineStatus: String {
        case green
        case yellow
        case red
    }

    let id: UUID
    let petName: String
    let breed: String
    let vaccineStatus: VaccineStatus
}
