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

        var feedItems: [FeedItem] {
            return self.items.map({ $0.item })
        }
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

    internal static func map(_ data: Data, from response: HTTPURLResponse) -> (Result<[FeedItem], RemoteFeedLoader.Error>) {
        guard response.statusCode == OK_200,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }
        return .success(root.feedItems)
    }
}
