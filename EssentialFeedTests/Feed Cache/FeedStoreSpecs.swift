//
//  FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 4/7/21.
//

import Foundation

protocol FeedStoreSpecs {
    func test_retrieve_deliverEmptyOnEmptyCache()
    func test_retrieve_hasNoSideEffectsOnEmptyCache()
    func test_retrieve_deliverFoundValueOnNonEmptyCache()
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache()
    func test_retrieve_deliverFailureOnRetrievalError()
    func test_retrieve_hasNoSideEffectsOnFailure()

    func test_insert_overridesPreviouslyInsertedCacheValues()
    func test_insert_deliversErrorOnInsertionError()

    func test_delete_hasNoSideEffectsOnEmptyCache()
    func test_delete_emptiesPreviouslyInsertedCache()
    func test_delete_deliversErrorOnDeletionError()

    func test_storeSideEffects_runSerially()
}

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
    func test_retrieve_deliverFailureOnRetrievalError()
    func test_retrieve_hasNoSideEffectsOnFailure()
}

protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
    func test_insert_deliversErrorOnInsertionError()
    func test_insert_hasNoSideEffectsOnInsertError()
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
    func test_delete_deliversErrorOnDeletionError()
    func test_delete_hasNoSideEffectsOnDeletionError()
}

typealias FailableFeedStore = FailableInsertFeedStoreSpecs & FailableDeleteFeedStoreSpecs & FailableRetrieveFeedStoreSpecs
