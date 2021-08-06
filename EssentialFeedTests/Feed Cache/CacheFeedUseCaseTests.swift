//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 17/6/21.
//

import XCTest
import EssentialFeed

class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessage, [])
    }

    func test_save_requestsCachedDeletion() {
        let (sut, store) = makeSUT()

        sut.save(uniqueImageFeed().models, completion: { _ in })
        XCTAssertEqual(store.receivedMessage, [.deleteCachedFeed])
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyError()

        expect(sut, toCompleteWithError: deletionError as NSError) {
            store.completeDeletion(with: deletionError)
        }
    }

    func test_save_requestCacheInsertionWithTimesStampOnSuccessfulDeletion() {
        let timestamp = Date()
        let feed = uniqueImageFeed()
        let (sut, store) = makeSUT(currentDate: { timestamp })

        sut.save(feed.models, completion: { _ in })
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.receivedMessage, [.deleteCachedFeed, .insert(feed.local, timestamp)])
    }

    func test_save_failsOnDeletionError() {
        let deletionError = anyError()
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWithError: deletionError as NSError) {
            store.completeDeletion(with: deletionError)
        }
    }

    func test_save_failsOnInsertError() {
        let insertError = anyError()
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWithError: insertError as NSError) {
            store.completeDeletionSuccessfully()
            store.completeInsert(with: insertError)
        }
    }

    func test_save_succeedsOnSuccessfulInsertion() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWithError: nil) {
            store.completeDeletionSuccessfully()
            store.completionInsertionSuccessfully()
        }
    }

    func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

        var receivedError = [LocalFeedLoader.SaveResult]()
        sut?.save(uniqueImageFeed().models, completion: { receivedError.append($0) })

        sut = nil
        store.completeDeletion(with: anyError())

        XCTAssertTrue(receivedError.isEmpty)
    }

    func test_save_doesNotDeliverErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

        var receivedError = [LocalFeedLoader.SaveResult]()
        sut?.save(uniqueImageFeed().models, completion: { receivedError.append($0)} )

        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsert(with: anyError())

        XCTAssertEqual(receivedError.count, 0)
    }

    //MARK: - HELPER

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let store = FeedStoreSpy()
        let loader = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)
        return (loader, store)
    }

    private func expect(_ sut: LocalFeedLoader, toCompleteWithError expectedError: NSError?, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "wait for completion")

        var receivedError: Error?
        sut.save(uniqueImageFeed().models) { (error) in
            receivedError = error
            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
    }
}
