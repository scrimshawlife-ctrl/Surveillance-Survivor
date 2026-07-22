import Foundation

final class RunReceiptStore {
    static let storageKey = "surveillance.latestRunReceipt"

    private let defaults: UserDefaults
    private(set) var latest: DeviceRunReceipt?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        latest = defaults.data(forKey: Self.storageKey).flatMap { try? JSONDecoder().decode(DeviceRunReceipt.self, from: $0) }
    }

    func save(_ receipt: DeviceRunReceipt) {
        guard let data = try? JSONEncoder().encode(receipt) else { return }
        defaults.set(data, forKey: Self.storageKey)
        latest = receipt
    }
}
