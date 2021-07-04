//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 3/7/21.
//

import XCTest
import EssentialFeed

class CodableFeedStore: FeedStore {

    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date

        var localFeed: [LocalFeedImage] {
            return feed.map({ $0.local } )
        }
    }

    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL

        init(_ image: LocalFeedImage) {
            self.id = image.id
            self.description = image.description
            self.location = image.location
            self.url = image.url
        }

        var local: LocalFeedImage {
            return LocalFeedImage(id: id,
                                  description: description,
                                  location: location,
                                  url: url)
        }
    }

    private let storeURL: URL

    init(storeURL: URL) {
        self.storeURL = storeURL
    }

    func retrieve(completion: @escaping RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }

        do {
            let decoder = JSONDecoder()
            let cache = try decoder.decode(Cache.self, from: data)
            completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
        } catch {
            completion(.failure(error))
        }
    }

    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        do {
            let encoder = JSONEncoder()
            let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
            let encoded = try encoder.encode(cache)
            try encoded.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }

    func deleteCacheFeed(completion: @escaping DeletionCompletion) {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return completion(nil)
        }

        do {
            try FileManager.default.removeItem(at: storeURL)
            completion(nil)
        } catch {
             completion(error)
        }
    }
}

class CodableFeedStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()

        setupEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()

        undoStoreSideEffects()
    }

    func test_retrieve_deliverEmptyOnEmptyCache() {
        let sut = makeSUT()

        expect(sut, toRetrieve: .empty)
    }

    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        expect(sut, toRetrieveTwice: .empty)
    }

    func test_retrieve_deliverFoundValueOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        insert((feed, timestamp), to: sut)

        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        insert((feed, timestamp), to: sut)

        expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
    }

    func test_retrieve_deliverFailureOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "Invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        expect(sut, toRetrieve: .failure(anyError()))
    }

    func test_retrieve_hasNoSideEffectsOnFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        expect(sut, toRetrieveTwice: .failure(anyError()))
    }

    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()

        let firstInsertError = insert((uniqueImageFeed().local, Date()), to: sut)
        XCTAssertNil(firstInsertError, "Expected to insert cache successfully")

        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        let latestInsertError = insert((latestFeed, latestTimestamp), to: sut)

        XCTAssertNil(latestInsertError, "Expected to override cache successfully")
        expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
    }

    func test_insert_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        let insertError = insert((feed, timestamp), to: sut)
        XCTAssertNotNil(insertError, "Expect cache insert to fail with an error")
    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        let deletionError = deleteCache(from: sut)
        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")

        expect(sut, toRetrieve: .empty)
    }

    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        let insertError = insert((feed, timestamp), to: sut)
        XCTAssertNil(insertError, "Expected insert cache successfully")

        let deleteError = deleteCache(from: sut)
        XCTAssertNil(deleteError, "Expected delete cache successfully")

        expect(sut, toRetrieve: .empty)
    }

    func test_delete_deliversErrorOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissionURL)

        let deletionError = deleteCache(from: sut)

        XCTAssertNotNil(deletionError, "Expect cache deletion to fail")
        expect(sut, toRetrieve: .empty)
    }

    //MARK: - HELPER

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func deleteCache(from sut: CodableFeedStore) -> Error? {
        let exp = expectation(description: "wait for completion")

        var retrievedError: Error?
        sut.deleteCacheFeed { (error) in
            retrievedError = error
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        return retrievedError
    }

    @discardableResult
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore) -> Error? {
        let exp = expectation(description: "wait for completion")

        var insertionError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { (error) in
            insertionError = error
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }

    private func expect(_ sut: CodableFeedStore, toRetrieveTwice expectResult: RetrieveCachedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectResult,file: file, line: line)
        expect(sut, toRetrieve: expectResult,file: file, line: line)
    }

    private func expect(_ sut: CodableFeedStore, toRetrieve expectResult: RetrieveCachedResult, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "wait for completion")

        sut.retrieve { (retrievedResult) in
            switch (expectResult, retrievedResult) {
            case (.empty, .empty),
                 (.failure, .failure):
                break

            case let (.found(expectFeed, expectTimestamp), .found(retrievedFeed, retrievedTimestamp)):
                XCTAssertEqual(expectFeed, retrievedFeed)
                XCTAssertEqual(expectTimestamp, retrievedTimestamp)

            default:
                XCTFail("Expect to retrieved \(expectResult) but got \(retrievedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }

    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }

    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }

    private func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }

    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .systemDomainMask).first!
    }
}
