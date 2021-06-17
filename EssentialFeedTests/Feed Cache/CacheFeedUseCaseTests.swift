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

    init(store: FeedStore) {
        self.store = store
    }

    func save(_ items: [FeedItem]) {
        store.deleteCacheFeed()
    }
}

class FeedStore {

    var deleteCachedFeedCallCount = 0

    func deleteCacheFeed() {
        deleteCachedFeedCallCount += 1
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

    //MARK: - HELPER

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (FeedLoader, FeedStore) {
        let store = FeedStore()
        let loader = FeedLoader(store: store)
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
}
