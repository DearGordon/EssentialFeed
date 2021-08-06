//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Gordon Feng on 29/5/21.
//

import Foundation

public final class RemoteFeedLoader {

    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }

}

extension RemoteFeedLoader: FeedLoader {

    public func load(completion: @escaping ((Result<[FeedImage], Swift.Error>) -> Void)) {
        client.get(from: url, completion: { [weak self] (result) in
            guard self != nil else { return }

            switch result {
            case let .success((data, response)):
                completion(RemoteFeedLoader.map(data, response: response))
            case .failure(_):
                completion(.failure(Error.connectivity))
            }
        })
    }

    private static func map(_ data: Data, response: HTTPURLResponse) -> Result<[FeedImage], Swift.Error> {
        do {
            let items = try FeedItemsMapper.map(data, from: response)
            return .success(items.toModel())
        } catch {
            return .failure(error)
        }
    }
}

private extension Array where Element == RemoteFeedItem {

    func toModel() -> [FeedImage] {
        return map({
            FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image)
        })
    }
}
