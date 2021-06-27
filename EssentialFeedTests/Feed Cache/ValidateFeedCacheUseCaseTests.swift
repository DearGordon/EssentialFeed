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

        sut.validateCache(completion: { _ in })
        store.completeRetrievalWith(anyError())

        XCTAssertEqual(store.receivedMessage, [.retrieve, .deleteCachedFeed])
    }

    func test_validateCache_doesNotDeleteCacheOnEmptyCache() {
        let (sut, store) = makeSUT()

        sut.validateCache(completion: { _ in })
        store.completeRetrievalWithEmptyCache()

        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }

    func test_validate_doesNotDeleteCacheOnLessThanSevenDaysOldCache() {
        let (sut, store) = makeSUT()
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThenSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(days: 1)

        sut.validateCache(completion: { _ in })
        store.completeRetrieval(with: feed.localModel, timestamp: lessThenSevenDaysOldTimestamp)

        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }

    func test_validateCache_deletesCacheOnSevenDaysOldCache() {
        let (sut, store) = makeSUT()
        let feed = uniqueImageFeed()
        let fixCurrentDate = Date()
        let sevenDaysOldTimestamp = fixCurrentDate.adding(days: -7)

        sut.validateCache(completion: { _ in })
        store.completeRetrieval(with: feed.localModel, timestamp: sevenDaysOldTimestamp)

        XCTAssertEqual(store.receivedMessage, [.retrieve, .deleteCachedFeed])
    }

    func test_validateCache_deleteCacheOnMoreThanSevenDaysOldCache() {
        let (sut, store) = makeSUT()
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(days: -1)

        sut.validateCache(completion: { _ in })
        store.completeRetrieval(with: feed.localModel, timestamp: moreThanSevenDaysOldTimestamp)

        XCTAssertEqual(store.receivedMessage, [.retrieve, .deleteCachedFeed])
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
