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
                    completion(.success(root.items.map({ $0.item })))
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
    let items: [Item]
}

//cause we will have feedItem from different source, remote source or local source, so we won't dependancy model on FeedItem itself but on RemoteFeedLoader and LocalFeedLoader seperate, so if server change api's property, will not effect whole FeedItem module
private struct Item: Codable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL

    var item: FeedItem {
        return FeedItem(id: self.id,
                        description: self.description,
                        location: self.location,
                        imageURL: self.image)
    }
}
