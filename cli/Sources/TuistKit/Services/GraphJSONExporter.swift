import FileSystem
import Foundation
import Path
import XcodeGraph

/// Writes a graph in the format of `tuist graph --format json`.
public struct GraphJSONExporter {
    private let fileSystem: FileSysteming

    public init(fileSystem: FileSysteming = FileSystem()) {
        self.fileSystem = fileSystem
    }

    public func export(graph: XcodeGraph.Graph, at path: AbsolutePath) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        let jsonData = try encoder.encode(graph)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw GraphServiceError.encodingError(GraphFormat.json.rawValue)
        }

        try await fileSystem.writeText(jsonString, at: path, encoding: .utf8, options: [.overwrite])
    }
}
