//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 4/7/21.
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {

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
