//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Gordon Feng on 29/5/21.
//

import Foundation

public protocol HTTPClient {
    func get(form url: URL, completion: @escaping ((Result<SuccessItem, Error>) -> Void))
}

public typealias SuccessItem = (data: Data, response: HTTPURLResponse)

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
            case .success(let successItem):

                if successItem.response.statusCode == 200,
                   let root = try? JSONDecoder().decode(Root.self, from: successItem.data) {
                    completion(.success(root.items))
                } else {
                    completion(.failure(.invalidData))
                }
            case .failure(_):
                completion(.failure(.connectivity))
            }
        })
    }
}

private struct Root: Codable {
    let items: [FeedItem]
}
