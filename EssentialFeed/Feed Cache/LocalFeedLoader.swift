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
    private let calendar = Calendar(identifier: .gregorian)

    public typealias SaveResult = Error?
    public typealias LoadResult = Result<[FeedImage], Error>

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

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

    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .failure(error):
                completion(.failure(error))

            case let .found(feed, timestamp) where self.validDate(timestamp):
                completion(.success(feed.toModels()))

            case .found:
                completion(.success([]))

            case .empty:
                completion(.success([]))
            }
        }
    }

    public func validateCache(completion: @escaping (LoadResult) -> Void) {
        store.retrieve(completion: { [unowned self] result in
            switch result {
            case .failure:
                self.store.deleteCacheFeed(completion: { _ in })

            case let .found(_, timestamp) where !self.validDate(timestamp):
                self.store.deleteCacheFeed(completion: { _ in })

            case .empty, .found: break
            }
        })
    }

    private let maxCacheAgeInDays: Int = 7

    private func validDate(_ timestamp: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return currentDate() < maxCacheAge
    }

    private func cache(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.toLocal(), timestamp: self.currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
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
