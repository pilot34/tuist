import FileSystem
import Foundation
import TuistCore
import TuistLoader
import TuistSupport
import XcodeGraph
import XCTest
@testable import TuistKit
@testable import TuistTesting

final class ManifestGraphLoaderIntegrationTests: TuistTestCase {
    var subject: ManifestGraphLoader!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let manifestLoader = ManifestLoader()
        let workspaceMapper = SequentialWorkspaceMapper(mappers: [])
        let graphMapper = SequentialGraphMapper([])
        subject = ManifestGraphLoader(
            manifestLoader: manifestLoader,
            workspaceMapper: workspaceMapper,
            graphMapper: graphMapper
        )
    }

    override func tearDownWithError() throws {
        subject = nil
        try super.tearDownWithError()
    }

    // MARK: - Tests

    func test_load_workspace() async throws {
        // Given
        let path = try await temporaryFixture("WorkspaceWithPlugins")

        // When
        let (result, _, _, _) = try await subject.load(path: path, disableSandbox: true)

        // Then
        XCTAssertEqual(result.workspace.name, "Workspace")
        XCTAssertEqual(result.projects.values.map(\.name).sorted(), [
            "App",
            "FrameworkA",
            "FrameworkB",
        ])
    }

    func test_load_exportsTheGraphBeforeMappersRun_whenAGraphOutputIsSet() async throws {
        // Given
        let path = try await temporaryFixture("WorkspaceWithPlugins")
        let outputDirectory = try temporaryPath()
        let subject = ManifestGraphLoader(
            manifestLoader: ManifestLoader(),
            workspaceMapper: SequentialWorkspaceMapper(mappers: []),
            graphMapper: RenamingGraphMapper(name: "Mapped")
        )

        // When
        let (graph, _, _, _) = try await GraphOutput.$current.withValue(GraphOutput(directory: outputDirectory)) {
            try await subject.load(path: path, disableSandbox: true)
        }
        let (graphWithoutMappers, _, _, _) = try await self.subject.load(path: path, disableSandbox: true)

        // Then
        let exportedGraphData = try await FileSystem().readFile(at: outputDirectory.appending(component: "graph.json"))
        XCTAssertEqual(graph.name, "Mapped")
        XCTAssertEqual(try JSONDecoder().decode(Graph.self, from: exportedGraphData), graphWithoutMappers)
    }

    func test_load_exportsTheGraphOnce_whenLoadingItMoreThanOnce() async throws {
        // Given
        let path = try await temporaryFixture("WorkspaceWithPlugins")
        let outputDirectory = try temporaryPath()
        let graphPath = outputDirectory.appending(component: "graph.json")
        let fileSystem = FileSystem()

        // When
        try await GraphOutput.$current.withValue(GraphOutput(directory: outputDirectory)) {
            _ = try await subject.load(path: path, disableSandbox: true)
            try await fileSystem.remove(graphPath)
            _ = try await subject.load(path: path, disableSandbox: true)
        }

        // Then
        let exported = try await fileSystem.exists(graphPath)
        XCTAssertFalse(exported)
    }

    func test_load_doesntExportTheGraph_whenNoGraphOutputIsSet() async throws {
        // Given
        let path = try await temporaryFixture("WorkspaceWithPlugins")
        let outputDirectory = try temporaryPath()

        // When
        _ = try await subject.load(path: path, disableSandbox: true)

        // Then
        let exported = try await FileSystem().exists(outputDirectory.appending(component: "graph.json"))
        XCTAssertFalse(exported)
    }

    func test_load_project() async throws {
        // Given
        let path = try await temporaryFixture("WorkspaceWithPlugins")
            .appending(component: "App")

        // When
        let (result, _, _, _) = try await subject.load(path: path, disableSandbox: true)

        // Then
        XCTAssertEqual(result.workspace.name, "App")
        XCTAssertEqual(result.projects.values.map(\.name).sorted(), [
            "App",
            "FrameworkA",
            "FrameworkB",
        ])
    }
}

private struct RenamingGraphMapper: GraphMapping {
    let name: String

    func map(graph: Graph, environment: MapperEnvironment) async throws -> (Graph, [SideEffectDescriptor], MapperEnvironment) {
        var graph = graph
        graph.name = name
        return (graph, [], environment)
    }
}
