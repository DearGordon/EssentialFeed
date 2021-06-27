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

    func test_load_deliversCachedImagesOnLessThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWith: .success(feed.model)) {
            store.completeRetrieval(with: feed.localModel, timestamp: lessThanSevenDaysOldTimestamp)
        }
    }

    func test_load_deliverNoImagesOnSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: feed.localModel, timestamp: sevenDaysOldTimestamp)
        }
    }

    func test_load_deliverNoImagesOnMoreThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(days: -1)
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: feed.localModel, timestamp: moreThanSevenDaysOldTimestamp)
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

    func test_load_hasNoSideEffectOnLessThanSevenDaysOldCache() {
        let (sut, store) = makeSUT()
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThenSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(days: 1)

        sut.load(completion: { _ in })
        store.completeRetrieval(with: feed.localModel, timestamp: lessThenSevenDaysOldTimestamp)

        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }

    func test_load_deletesCacheOnSevenDaysOldCache() {
        let (sut, store) = makeSUT()
        let feed = uniqueImageFeed()
        let fixCurrentDate = Date()
        let sevenDaysOldTimestamp = fixCurrentDate.adding(days: -7)

        sut.load(completion: { _ in })
        store.completeRetrieval(with: feed.localModel, timestamp: sevenDaysOldTimestamp)

        XCTAssertEqual(store.receivedMessage, [.retrieve, .deleteCachedFeed])
    }

    func test_load_deleteCacheOnMoreThanSevenDaysOldCache() {
        let (sut, store) = makeSUT()
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(days: -1)

        sut.load(completion: { _ in })
        store.completeRetrieval(with: feed.localModel, timestamp: moreThanSevenDaysOldTimestamp)

        XCTAssertEqual(store.receivedMessage, [.retrieve, .deleteCachedFeed])
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

    private func uniqueImage() -> FeedImage {
        return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }

    private func uniqueImageFeed() -> (model: [FeedImage], localModel: [LocalFeedImage]) {
        let items = [uniqueImage(), uniqueImage()]
        let localItems = items.map {
            LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
        }
        return (items, localItems)
    }

    private func anyError() -> NSError {
        return NSError(domain: "any Error", code: 0)
    }

    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
}

private extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
