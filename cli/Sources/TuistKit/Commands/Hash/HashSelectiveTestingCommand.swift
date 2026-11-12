import ArgumentParser
import Foundation
import TuistEnvKey
import TuistExtension
import TuistHasher
import TuistSupport

/// A command to hash a generated project.
public struct HashSelectiveTestingCommand: AsyncParsableCommand, ProjectPathProviding, GraphOutputCommand {
    public init() {}

    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "selective-testing",
            _superCommandName: "hash",
            abstract: "Returns the hashes that will be used to persist targets' test results to select tests in future test runs."
        )
    }

    @Option(
        name: .shortAndLong,
        help: "The path to the directory that contains the project whose tests will run selectively.",
        completion: .directory,
        envKey: .hashCachePath
    )
    public var path: String?

    @Option(
        name: .long,
        help: "Also export the project graph to graph.json in this directory, in the format of `tuist graph --format json`, without loading the graph again.",
        completion: .directory,
        envKey: .graphExportPath
    )
    public var graphOutputPath: String?

    public func run() async throws {
        try await HashSelectiveTestingCommandService(
            generatorFactory: Extension.generatorFactory,
            cacheStorageFactory: Extension.cacheStorageFactory
        )
        .run(
            path: path
        )
    }
}
