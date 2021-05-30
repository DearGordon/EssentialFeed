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


    public func load(completion: @escaping ((Result<[FeedItem], RemoteFeedLoader.Error>) -> Void)) {
        client.get(form: url, completion: { [weak self] (result) in
            guard self != nil else { return }   //why we add this line cause if self is nil, this closure will still run to the bottom, and will retain cycle with Static member - FeedItemsMapper

            switch result {
            case .success(let successItem):
                let result = FeedItemsMapper.map(successItem.data, from: successItem.response)
                completion(result)
            case .failure(_):
                completion(.failure(.connectivity))
            }
        })
    }
}
