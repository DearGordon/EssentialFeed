//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Gordon Feng on 30/5/21.
//

import Foundation

internal final class FeedItemsMapper {

    private struct Root: Codable {
        let items: [Item]
    }

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

    private static var OK_200: Int = 200

    internal static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == OK_200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        let root = try JSONDecoder().decode(Root.self, from: data)
        return root.items.map({ $0.item})
    }
}
