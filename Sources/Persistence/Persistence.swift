import Foundation

public protocol SettingsStore {
    func save<T: Encodable>(_ value: T, forKey key: String) throws
    func load<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T?
}

public final class InMemorySettingsStore: SettingsStore {
    private var values: [String: Data] = [:]
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init() {}

    public func save<T>(_ value: T, forKey key: String) throws where T : Encodable {
        values[key] = try encoder.encode(value)
    }

    public func load<T>(_ type: T.Type, forKey key: String) throws -> T? where T : Decodable {
        guard let data = values[key] else { return nil }
        return try decoder.decode(type, from: data)
    }
}

public final class FileSettingsStore: SettingsStore {
    private let directoryURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let fileManager: FileManager

    public init(directoryURL: URL, fileManager: FileManager = .default) {
        self.directoryURL = directoryURL
        self.fileManager = fileManager
    }

    public func save<T>(_ value: T, forKey key: String) throws where T : Encodable {
        try ensureDirectoryExists()
        let targetURL = directoryURL.appendingPathComponent("\(key).json")
        let data = try encoder.encode(value)
        try data.write(to: targetURL, options: .atomic)
    }

    public func load<T>(_ type: T.Type, forKey key: String) throws -> T? where T : Decodable {
        let targetURL = directoryURL.appendingPathComponent("\(key).json")
        guard fileManager.fileExists(atPath: targetURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: targetURL)
        return try decoder.decode(type, from: data)
    }

    private func ensureDirectoryExists() throws {
        guard !fileManager.fileExists(atPath: directoryURL.path) else {
            return
        }

        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }
}

public struct SettingsRepository<Value: Codable> {
    private let key: String
    private let store: any SettingsStore

    public init(key: String, store: any SettingsStore) {
        self.key = key
        self.store = store
    }

    public func save(_ value: Value) throws {
        try store.save(value, forKey: key)
    }

    public func load() throws -> Value? {
        try store.load(Value.self, forKey: key)
    }
}
