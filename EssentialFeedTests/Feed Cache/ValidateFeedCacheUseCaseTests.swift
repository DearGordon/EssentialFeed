//
//  ValidateFeedCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 27/6/21.
//

import XCTest
import EssentialFeed

class ValidateFeedCacheUseCaseTests: XCTestCase {

    func test_init_doseNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessage, [])
    }

    func test_validateCache_deleteCacheOnRetrievalError() {
        let (sut, store) = makeSUT()

        sut.validateCache()
        store.completeRetrievalWith(anyError())

        XCTAssertEqual(store.receivedMessage, [.retrieve, .deleteCachedFeed])
    }

    func test_validateCache_doesNotDeleteCacheOnEmptyCache() {
        let (sut, store) = makeSUT()

        sut.validateCache()
        store.completeRetrievalWithEmptyCache()

        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }

    func test_validate_doesNotDeleteNonExpiredCache() {
        let (sut, store) = makeSUT()
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)

        sut.validateCache()
        store.completeRetrieval(with: feed.local, timestamp: nonExpiredTimestamp)

        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }

    func test_validateCache_deletesCacheOnCacheExpiration() {
        let (sut, store) = makeSUT()
        let feed = uniqueImageFeed()
        let fixCurrentDate = Date()
        let expirationTimestamp = fixCurrentDate.minusFeedCacheMaxAge()

        sut.validateCache()
        store.completeRetrieval(with: feed.local, timestamp: expirationTimestamp)

        XCTAssertEqual(store.receivedMessage, [.retrieve, .deleteCachedFeed])
    }

    func test_validateCache_deleteExpiredCache() {
        let (sut, store) = makeSUT()
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)

        sut.validateCache()
        store.completeRetrieval(with: feed.local, timestamp: expiredTimestamp)

        XCTAssertEqual(store.receivedMessage, [.retrieve, .deleteCachedFeed])
    }

    func test_validateCache_doesNotDeleteInvalidCacheAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

        sut?.validateCache()

        sut = nil
        store.completeRetrievalWith(anyError())

        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }

    //MARK: - HELPER
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (loader: LocalFeedLoader, story: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
}
