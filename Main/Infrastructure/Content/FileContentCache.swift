import CryptoKit
import Foundation

actor FileContentCache: ContentCache {
    // MARK: - Properties

    private let rootDirectory: URL
    private let fileManager: FileManager

    // MARK: - Init

    init(
        rootDirectory: URL,
        fileManager: FileManager = .default
    ) {
        self.rootDirectory = rootDirectory
        self.fileManager = fileManager
    }

    // MARK: - ContentCache

    func readCurrent() async throws -> CachedContent? {
        try readContent(pointerURL: currentPointerURL)
    }

    func readPrevious() async throws -> CachedContent? {
        try readContent(pointerURL: previousPointerURL)
    }

    func promote(_ content: CachedContent) async throws {
        try prepareDirectories()

        let payloadName = Self.payloadName(for: content.data)
        let payloadURL = payloadsDirectory.appendingPathComponent(payloadName)
        if !fileManager.fileExists(atPath: payloadURL.path) {
            try content.data.write(to: payloadURL, options: .atomic)
        }

        if let currentPointer = try readPointer(at: currentPointerURL) {
            try writePointer(currentPointer, to: previousPointerURL)
        }

        let newPointer = Pointer(
            payloadName: payloadName,
            manifestRevision: content.manifestRevision
        )
        try writePointer(newPointer, to: currentPointerURL)
    }

    // MARK: - Private methods

    private func prepareDirectories() throws {
        try fileManager.createDirectory(
            at: payloadsDirectory,
            withIntermediateDirectories: true
        )

        var root = rootDirectory
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try root.setResourceValues(resourceValues)
    }

    private func readContent(pointerURL: URL) throws -> CachedContent? {
        guard let pointer = try readPointer(at: pointerURL) else {
            return nil
        }

        let payloadURL = payloadsDirectory.appendingPathComponent(pointer.payloadName)
        let data = try Data(contentsOf: payloadURL, options: .mappedIfSafe)
        return CachedContent(
            data: data,
            manifestRevision: pointer.manifestRevision
        )
    }

    private func readPointer(at url: URL) throws -> Pointer? {
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Pointer.self, from: data)
    }

    private func writePointer(_ pointer: Pointer, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        try encoder.encode(pointer).write(to: url, options: .atomic)
    }

    private static func payloadName(for data: Data) -> String {
        let hash = SHA256.hash(data: data)
        let digest = hash.map { String(format: "%02x", $0) }.joined()
        return digest + String.jsonExtension
    }
}

// MARK: - DTO

private extension FileContentCache {
    struct Pointer: Codable {
        let payloadName: String
        let manifestRevision: Int
    }
}

// MARK: - Computed properties

private extension FileContentCache {
    var payloadsDirectory: URL {
        rootDirectory.appendingPathComponent(String.payloadsDirectoryName)
    }

    var currentPointerURL: URL {
        rootDirectory.appendingPathComponent(String.currentPointerName)
    }

    var previousPointerURL: URL {
        rootDirectory.appendingPathComponent(String.previousPointerName)
    }
}

// MARK: - Constants

private extension String {
    static let currentPointerName = "current.json"
    static let jsonExtension = ".json"
    static let payloadsDirectoryName = "payloads"
    static let previousPointerName = "previous.json"
}
