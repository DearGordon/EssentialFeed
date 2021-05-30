//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Gordon Feng on 29/5/21.
//

import Foundation

public protocol HTTPClient {
    func get(form url: URL, completion: @escaping ((Result<(Data, HTTPURLResponse), Error>) -> Void))
}

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
        client.get(form: url, completion: { (result) in

            switch result {
            case .success(_):
//                if response.statusCode != 200 {
                    completion(.failure(.invalidData))
//                } else {
//                    completion(.success(nil))
//                }
            case .failure(_):
                completion(.failure(.connectivity))
            }
        })
    }
}
