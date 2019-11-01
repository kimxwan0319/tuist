import Basic
import Foundation
import XCTest

@testable import TuistSupportTesting
@testable import TuistGenerator

final class GraphToDotGraphMapperTests: XCTestCase {
    var subject: GraphToDotGraphMapper!

    override func setUp() {
        super.setUp()
        subject = GraphToDotGraphMapper()
    }

    func test_map() throws {
        // Given
        let framework = FrameworkNode.test(path: AbsolutePath("/XcodeProj.framework"))
        let library = LibraryNode.test(path: AbsolutePath("/RxSwift.a"))
        let sdk = try SDKNode(name: "CoreData.framework", platform: .iOS, status: .required)

        let core = TargetNode.test(target: Target.test(name: "Core"), dependencies: [
            framework, library, sdk,
        ])
        let iOSApp = TargetNode.test(target: Target.test(name: "Tuist iOS"), dependencies: [core])
        let watchApp = TargetNode.test(target: Target.test(name: "Tuist watchOS"), dependencies: [core])

        let cache = GraphLoaderCache()
        cache.add(precompiledNode: framework)
        cache.add(precompiledNode: library)
        cache.add(targetNode: core)
        cache.add(targetNode: iOSApp)
        cache.add(targetNode: watchApp)
        let graph = Graph.test(cache: cache, entryNodes: [iOSApp, watchApp])

        // When
        let got = subject.map(graph: graph)

        // Then
        let expected = DotGraph(name: "Project Dependencies Graph",
                                type: .directed,
                                nodes: Set([
                                    .init(name: "Tuist iOS"),
                                    .init(name: "CoreData"),
                                    .init(name: "RxSwift"),
                                    .init(name: "XcodeProj"),
                                    .init(name: "Core"),
                                    .init(name: "Tuist watchOS"),
                                ]), dependencies: [
                                    .init(from: "Tuist iOS", to: "Core"),
                                    .init(from: "Tuist watchOS", to: "Core"),
                                    .init(from: "Core", to: "XcodeProj"),
                                    .init(from: "Core", to: "RxSwift"),
                                    .init(from: "Core", to: "CoreData"),
                                ])
        XCTAssertEqual(got, expected)
    }
}
