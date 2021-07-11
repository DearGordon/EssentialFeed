//
//  CoreDataFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 11/7/21.
//

import XCTest
import EssentialFeed


class CoreDataFeedStore: FeedStore {

    func retrieve(completion: @escaping RetrievalCompletion) {
        completion(.empty)
    }

    func deleteCacheFeed(completion: @escaping DeletionCompletion) {

    }

    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {

    }
}

class CoreDataFeedStoreTests: XCTestCase, FeedStoreSpecs {
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()

        assertThatRetrieveDeliversEmptyCache(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnEmptyCache() {

    }

    func test_retrieve_deliversFoundValueOnNonEmptyCache() {

    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {

    }

    func test_retrieve_deliversFailureOnRetrievalError() {

    }

    func test_retrieve_hasNoSideEffectsOnFailure() {

    }

    func test_insert_overridesPreviouslyInsertedCacheValues() {

    }

    func test_insert_deliversErrorOnInsertionError() {

    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {

    }

    func test_delete_emptiesPreviouslyInsertedCache() {

    }

    func test_delete_deliversErrorOnDeletionError() {

    }

    func test_storeSideEffects_runSerially() {

    }

    //MARK: - Helper

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let sut = CoreDataFeedStore()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
