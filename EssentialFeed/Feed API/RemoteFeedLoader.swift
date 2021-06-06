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

    public func load(completion: @escaping ((Result<[FeedItem], Swift.Error>) -> Void)) {
        client.get(from: url, completion: { [weak self] (result) in
            guard self != nil else { return }

            switch result {
            case let .success((data, response)):
                let result = FeedItemsMapper.map(data, from: response)
                completion(result)
            case .failure(_):
                completion(.failure(Error.connectivity))
            }
        })
    }


}
