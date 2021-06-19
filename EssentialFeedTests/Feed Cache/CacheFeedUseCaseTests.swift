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

    func save(_ items: [FeedItem], completion: @escaping ((Error) -> Void)) {
        store.deleteCacheFeed { [unowned self] error in
            if let error = error {
                completion(error)
            } else  {
                self.store.insert(items, timestamp: self.currentDate())
            }
        }
    }
}

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void

    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([FeedItem], Date)
    }

    private(set) var receivedMessage = [ReceivedMessage]()

    private var deletionCompletions = [DeletionCompletion]()

    func deleteCacheFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessage.append(.deleteCachedFeed)
    }

    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }

    func completeSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }

    func insert(_ items: [FeedItem], timestamp: Date) {
        receivedMessage.append(.insert(items, timestamp))
    }
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
        let items = [uniqueItem(), uniqueItem()]
        let deletionError = anyError()

        sut.save(items, completion: { _ in })
        store.completeDeletion(with: deletionError)

        XCTAssertEqual(store.receivedMessage, [.deleteCachedFeed])
    }

    func test_save_requestCacheInsertionWithTimesStampOnSuccessfulDeletion() {
        let timestamp = Date()
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT(currentDate: { timestamp })

        sut.save(items, completion: { _ in })
        store.completeSuccessfully()

        XCTAssertEqual(store.receivedMessage, [.deleteCachedFeed, .insert(items, timestamp)])
    }

    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(),uniqueItem()]
        let deletionError = anyError()

        let exp = expectation(description: "wait for closure")
        var receivedError: Error?
        sut.save(items) { (error) in
            receivedError = error
            exp.fulfill()
        }
        store.completeDeletion(with: deletionError)

        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedError as NSError?, deletionError as NSError)
    }

    //MARK: - HELPER

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (FeedLoader, FeedStore) {
        let store = FeedStore()
        let loader = FeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)
        return (loader, store)
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
}
