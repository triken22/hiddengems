import XCTest
@testable import HiddenGems

final class SpotRepositoryTests: XCTestCase {
    func testHashEmbeddingProducesDeterministicVector() throws {
        let dimension = 8
        let configuration = HybridAIConfiguration(openAIKey: "key", groqKey: nil, embeddingDimension: dimension)
        let service = HybridAIService(configuration: configuration)
        let spot = Spot(id: "1",
                        title: "Golden Gate Bridge",
                        subtitle: nil,
                        details: "San Francisco",
                        coordinate: .init(latitude: 37.8199, longitude: -122.4783),
                        address: nil,
                        tags: ["bridge"],
                        topics: [],
                        images: [],
                        groupId: nil,
                        userId: nil,
                        deleted: false,
                        version: 1,
                        createdAt: Date(),
                        updatedAt: Date())

        let vectorA = try awaitResult(service.embedding(for: spot))
        let vectorB = try awaitResult(service.embedding(for: spot))
        XCTAssertEqual(vectorA, vectorB)
        XCTAssertEqual(vectorA?.count, dimension)
    }

    private func awaitResult<T>(_ expression: @autoclosure () async throws -> T) throws -> T {
        let expectation = XCTestExpectation(description: "Await async")
        var result: Result<T, Error>!
        Task {
            do {
                result = .success(try await expression())
            } catch {
                result = .failure(error)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
        return try result.get()
    }
}
