//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Gordon Feng on 29/5/21.
//

import Foundation

public protocol HTTPClient {
    func get(form url: URL, completion: @escaping ((Error) -> Void))
}

public final class RemoteFeedLoader {

    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
    }

    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }


    public func load(completion: @escaping ((Result<FeedItem, Error>) -> Void) = { _ in }) {
        client.get(form: url, completion: { (error) in
            //if get error, then throw .connectivity error
            completion(.failure(.connectivity))
        })
    }
}
