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

    func save(_ items: [FeedItem]) {
        store.deleteCacheFeed { [unowned self] error in
            if error == nil {
                self.store.insert(items, timestamp: self.currentDate())
            }
        }
    }
}

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    var deleteCachedFeedCallCount = 0
    var inserts = [(items: [FeedItem], timestamp: Date)]()

    private var deletionCompletions = [DeletionCompletion]()

    func deleteCacheFeed(completion: @escaping DeletionCompletion) {
        deleteCachedFeedCallCount += 1
        deletionCompletions.append(completion)
    }

    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }

    func completeSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }

    func insert(_ items: [FeedItem], timestamp: Date) {
        inserts.append((items, timestamp))
    }
}

class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotDeleCacheUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }

    func test_save_requestsCachedDeletion() {

        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]

        sut.save(items)
        XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        let deletionError = anyError()

        sut.save(items)
        store.completeDeletion(with: deletionError)

        XCTAssertEqual(store.inserts.count, 0)
    }

    func test_save_requestCacheInsertionWithTimesStampOnSuccessfulDeletion() {
        let timestamp = Date()
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT(currentDate: { timestamp })

        sut.save(items)
        store.completeSuccessfully()

        XCTAssertEqual(store.inserts.count, 1)
        XCTAssertEqual(store.inserts.first?.items, items)
        XCTAssertEqual(store.inserts.first?.timestamp, timestamp)
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
