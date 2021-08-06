//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Gordon Feng on 20/6/21.
//

import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalFeedLoader {

    public typealias SaveResult = Error?

    public func save(_ feed: [FeedImage], completion: @escaping ((SaveResult) -> Void)) {
        store.deleteCacheFeed { [weak self] error in
            guard let self = self else { return }

            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(feed, completion: completion)
            }
        }
    }

    private func cache(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.toLocal(), timestamp: self.currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

extension LocalFeedLoader: FeedLoader {

    public typealias LoadResult = Result<[FeedImage], Error>

    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .failure(error):
                completion(.failure(error))

            case let .success(.some(cache)) where FeedCachePolicy.validDate(cache.timestamp, against: self.currentDate()):
                completion(.success(cache.feed.toModels()))

            case .success:
                completion(.success([]))
            }
        }
    }
}

extension LocalFeedLoader {

    public func validateCache() {
        store.retrieve(completion: { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure:
                self.store.deleteCacheFeed(completion: { _ in })

            case let .success(.some(cache)) where !FeedCachePolicy.validDate(cache.timestamp, against: self.currentDate()):
                self.store.deleteCacheFeed(completion: { _ in })

            case .success: break
            }
        })
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return self.map {
            return LocalFeedImage(id: $0.id,
                                  description: $0.description,
                                  location: $0.location,
                                  url: $0.url)
        }
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        return self.map {
            return FeedImage(id: $0.id,
                             description: $0.description,
                             location: $0.location,
                             url: $0.url)
        }
    }
}
