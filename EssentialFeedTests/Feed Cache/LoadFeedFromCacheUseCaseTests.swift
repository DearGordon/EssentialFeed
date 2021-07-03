//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 20/6/21.
//

import XCTest
import EssentialFeed

class LoadFeedFromCacheUseCaseTests: XCTestCase {

    func test_init_doesNotStoreMessageUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessage, [])
    }

    func test_load_requestCacheRetrieval() {
        let (sut, store) = makeSUT()

        sut.load { _ in }

        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }

    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyError()

        expect(sut, toCompleteWith: .failure(retrievalError), when: {
            store.completeRetrievalWith(retrievalError)
        })
    }

    func test_load_deliversNoImagesOnEmptyCache() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrievalWithEmptyCache()
        })
    }

    func test_load_deliversCachedImagesOnNonExpiredCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let NonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWith: .success(feed.model)) {
            store.completeRetrieval(with: feed.local, timestamp: NonExpiredTimestamp)
        }
    }

    func test_load_deliverNoImagesOnCacheExpiration() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: feed.local, timestamp: expirationTimestamp)
        }
    }

    func test_load_deliverNoImagesOnExpiredCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: feed.local, timestamp: expirationTimestamp)
        }
    }

    func test_load_hasNoSideEffectsOnRetrievalError() {
        let (sut, store) = makeSUT()

        sut.load(completion: { _ in })
        store.completeRetrievalWith(anyError())

        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }

    func test_load_hasNoSideEffectsOnEmptyCache() {
        let (sut, store) = makeSUT()

        sut.load(completion: { _ in } )
        store.completeRetrievalWithEmptyCache()

        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }

    func test_load_hasNoSideEffectOnNonExpiredCache() {
        let (sut, store) = makeSUT()
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)

        sut.load(completion: { _ in })
        store.completeRetrieval(with: feed.local, timestamp: nonExpiredTimestamp)

        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }

    func test_load_hasNoSideEffectOnCacheExpiration() {
        let (sut, store) = makeSUT()
        let feed = uniqueImageFeed()
        let fixCurrentDate = Date()
        let expirationTimestamp = fixCurrentDate.minusFeedCacheMaxAge()

        sut.load(completion: { _ in })
        store.completeRetrieval(with: feed.local, timestamp: expirationTimestamp)

        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }

    func test_load_hasNoSideEffectOnExpiredCache() {
        let (sut, store) = makeSUT()
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)

        sut.load(completion: { _ in })
        store.completeRetrieval(with: feed.local, timestamp: expiredTimestamp)

        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }

    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

        var receivedResults = [Result<[FeedImage], Error>]()
        sut?.load(completion: { receivedResults.append($0) })
        
        sut = nil
        store.completeRetrievalWithEmptyCache()

        XCTAssertEqual(receivedResults.count, 0)
    }

    //MARK: - HELPER
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let store = FeedStoreSpy()
        let loader = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)
        return (loader, store)
    }

    private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedResult: LocalFeedLoader.LoadResult, when action: () ->Void, file: StaticString = #file, line: UInt = #line) {

        let exp = expectation(description: "wait for completion")
        sut.load { (receivedResult) in
            switch (expectedResult, receivedResult) {
            case let (.success(expectImages), .success(receivedImages)):
                XCTAssertEqual(expectImages, receivedImages, file: file, line: line)

            case let (.failure(expectError as NSError), .failure(receivedError as NSError)):
                XCTAssertEqual(expectError, receivedError, file: file, line: line)

            default:
                XCTFail("Expect \(expectedResult), but received \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)
    }
}
