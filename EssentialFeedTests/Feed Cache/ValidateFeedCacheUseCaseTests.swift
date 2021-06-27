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


    //MARK: - HELPER
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (loader: LocalFeedLoader, story: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }

    private func anyError() -> NSError {
        return NSError(domain: "any Error", code: 0)
    }

}

