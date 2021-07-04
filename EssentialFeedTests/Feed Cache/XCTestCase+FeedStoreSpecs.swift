//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 4/7/21.
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {

    func assertThatRetrieveDeliversEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }

    func assertThatRetrieveHasNoSideEffect(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieveTwice: .empty)
    }

    func assertThatRetrieveDeliverFoundValuesOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        insert((feed, timestamp), to: sut)

        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }

    func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        insert((feed, timestamp), to: sut)

        expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
    }

    func assertThatInsertDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let insertionError = insert((uniqueImageFeed().local, Date()), to: sut)

        XCTAssertNil(insertionError, "Expected to insert cache successfully")
    }

    func assertThatInsertDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let insertError = insert((uniqueImageFeed().local, Date()), to: sut)

        XCTAssertNil(insertError, "Expected insert cache successfully")
    }

    func assertThatInsertOverridesPreviouslyInsertedCacheValues(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()

        insert((latestFeed, latestTimestamp), to: sut)

        expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
    }

    func assertThatDeleteDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Expected delete cache successfully")
    }

    func assertThatDeleteHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        deleteCache(from: sut)

        expect(sut, toRetrieve: .empty)
    }

    func assertThatDeleteDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert((uniqueImageFeed().local, Date()), to: sut)
        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Expected delete cache successfully")
    }

    func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert((uniqueImageFeed().local, Date()), to: sut)
        deleteCache(from: sut)

        expect(sut, toRetrieve: .empty)
    }

    func assertThatSideEffectsRunSerially(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
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

    @discardableResult
    func deleteCache(from sut: FeedStore) -> Error? {
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
    func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) -> Error? {
        let exp = expectation(description: "wait for completion")

        var insertionError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { (error) in
            insertionError = error
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }

    func expect(_ sut: FeedStore, toRetrieveTwice expectResult: RetrieveCachedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectResult,file: file, line: line)
        expect(sut, toRetrieve: expectResult,file: file, line: line)
    }

    func expect(_ sut: FeedStore, toRetrieve expectResult: RetrieveCachedResult, file: StaticString = #file, line: UInt = #line) {
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
}
