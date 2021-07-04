//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 3/7/21.
//

import XCTest
import EssentialFeed

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

    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()
        var completedOperationInOrder = [XCTestExpectation]()

        let op1 = expectation(description: "Operation 1")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { (_) in
            completedOperationInOrder.append(op1)
            op1.fulfill()
        }

        let op2 = expectation(description: "Operation 2")
        sut.deleteCacheFeed { (_) in
            completedOperationInOrder.append(op2)
            op2.fulfill()
        }

        let op3 = expectation(description: "Operation 3")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { (_) in
            completedOperationInOrder.append(op3)
            op3.fulfill()
        }

        wait(for: [op1, op2, op3], timeout: 5.0)
        XCTAssertEqual([op1, op2, op3], completedOperationInOrder, "Expect side-effects to run serially but operations finished in the wrong order")

    }

    //MARK: - HELPER

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func deleteCache(from sut: FeedStore) -> Error? {
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
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) -> Error? {
        let exp = expectation(description: "wait for completion")

        var insertionError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { (error) in
            insertionError = error
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }

    private func expect(_ sut: FeedStore, toRetrieveTwice expectResult: RetrieveCachedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectResult,file: file, line: line)
        expect(sut, toRetrieve: expectResult,file: file, line: line)
    }

    private func expect(_ sut: FeedStore, toRetrieve expectResult: RetrieveCachedResult, file: StaticString = #file, line: UInt = #line) {
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
