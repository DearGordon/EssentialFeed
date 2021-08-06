//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Gordon Feng on 20/6/21.
//

import Foundation

public typealias CachedFeed = (feed: [LocalFeedImage], timestamp: Date)

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void

    typealias RetrievalResult = Result<CachedFeed?, Error>
    typealias RetrievalCompletion = (RetrievalResult) -> Void

    /// Clients are responsible to dispatch to appropriate threads, if needed
    /// - Parameter completion: The completion handler can be invoked in any thread.
    func deleteCacheFeed(completion: @escaping DeletionCompletion)

    /// Clients are responsible to dispatch to appropriate threads, if needed
    ///   - completion: The completion handler can be invoked in any thread
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)

    /// Clients are responsible to dispatch to appropriate threads, if needed
    /// - Parameter completion: The completion handler can be invoked in any thread.
    func retrieve(completion: @escaping RetrievalCompletion)
}
