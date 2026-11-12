import Path
import TuistEnvironment
import TuistThreadSafe

/// A command that can export the project graph it loads, in the format of `tuist graph --format json`.
public protocol GraphOutputCommand {
    /// The directory to export `graph.json` to, or nil not to export the graph.
    var graphOutputPath: String? { get }
}

/// Where to export the project graph loaded while a command runs.
public final class GraphOutput: Sendable {
    @TaskLocal public static var current: GraphOutput?

    /// The path of the `graph.json` file to export.
    public let path: AbsolutePath
    private let exported = ThreadSafe(false)

    public init(directory: AbsolutePath) {
        path = directory.appending(component: "graph.json")
    }

    /// The graph output `command` asks for, with its directory resolved against the working directory.
    public static func requested(by command: Any) async throws -> GraphOutput? {
        guard let graphOutputPath = (command as? GraphOutputCommand)?.graphOutputPath else { return nil }
        return GraphOutput(directory: try await Environment.current.pathRelativeToWorkingDirectory(graphOutputPath))
    }

    /// Returns true the first time it's called. A command can load the graph more than once, but the graph
    /// before any mapper runs only depends on the manifests, so it's exported once.
    public func claimExport() -> Bool {
        exported.mutate { exported in
            defer { exported = true }
            return !exported
        }
    }
}
