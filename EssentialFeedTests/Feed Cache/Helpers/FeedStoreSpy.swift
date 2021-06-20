//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 20/6/21.
//

import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void

    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
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

    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping (Error?) -> Void) {
        insertionCompletions.append(completion)
        receivedMessage.append(.insert(feed, timestamp))
    }

    func completeInsert(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }

    func completionInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
}
