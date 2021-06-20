//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 17/6/21.
//

import XCTest
import EssentialFeed

class FeedLoader {

    private let store: FeedStore
    private let currentDate: () -> Date

    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    func save(_ items: [FeedItem], completion: @escaping ((Error?) -> Void)) {
        store.deleteCacheFeed { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                completion(error)
            } else  {
                self.store.insert(items, timestamp: self.currentDate(), completion: { [weak self] error in
                    guard self != nil else { return }
                    completion(error)
                })
            }
        }
    }
}

protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void

    func deleteCacheFeed(completion: @escaping DeletionCompletion)
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping (Error?) -> Void)
}

class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessage, [])
    }

    func test_save_requestsCachedDeletion() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]

        sut.save(items, completion: { _ in })
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
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT(currentDate: { timestamp })

        sut.save(items, completion: { _ in })
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.receivedMessage, [.deleteCachedFeed, .insert(items, timestamp)])
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
        var sut: FeedLoader? = FeedLoader(store: store, currentDate: Date.init)

        var receivedError = [Error?]()
        sut?.save([uniqueItem()], completion: { receivedError.append($0) })

        sut = nil
        store.completeDeletion(with: anyError())

        XCTAssertTrue(receivedError.isEmpty)
    }

    func test_save_doesNotDeliverErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: FeedLoader? = FeedLoader(store: store, currentDate: Date.init)

        var receivedError = [Error?]()
        sut?.save([uniqueItem()], completion: { receivedError.append($0)} )

        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsert(with: anyError())

        XCTAssertEqual(receivedError.count, 0)
    }

    //MARK: - HELPER

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (FeedLoader, FeedStoreSpy) {
        let store = FeedStoreSpy()
        let loader = FeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)
        return (loader, store)
    }

    private func expect(_ sut: FeedLoader, toCompleteWithError expectedError: NSError?, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "wait for completion")

        var receivedError: Error?
        sut.save([uniqueItem()]) { (error) in
            receivedError = error
            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
    }

    private func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), description: "any", location: "any", imageURL: anyURL())
    }

    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }

    private func anyError() -> Error {
        return NSError(domain: "Any Error", code: 0)
    }

    private class FeedStoreSpy: FeedStore {
        typealias DeletionCompletion = (Error?) -> Void
        typealias InsertionCompletion = (Error?) -> Void

        enum ReceivedMessage: Equatable {
            case deleteCachedFeed
            case insert([FeedItem], Date)
        }

        private(set) var receivedMessage = [ReceivedMessage]()

        private var deletionCompletions = [DeletionCompletion]()
        private var insertionCompletions = [InsertionCompletion]()

        func deleteCacheFeed(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            receivedMessage.append(.deleteCachedFeed)
        }

        func completeDeletion(with error: Error, at index: Int = 0) {
            deletionCompletions[index](error)
        }

        func completeDeletionSuccessfully(at index: Int = 0) {
            deletionCompletions[index](nil)
        }

        func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping (Error?) -> Void) {
            insertionCompletions.append(completion)
            receivedMessage.append(.insert(items, timestamp))
        }

        func completeInsert(with error: Error, at index: Int = 0) {
            insertionCompletions[index](error)
        }

        func completionInsertionSuccessfully(at index: Int = 0) {
            insertionCompletions[index](nil)
        }
    }
}
