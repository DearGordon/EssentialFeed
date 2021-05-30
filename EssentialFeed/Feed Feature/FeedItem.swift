//
//  FeedItem.swift
//  NetworkModule
//
//  Created by Gordon Feng on 28/5/21.
//

import Foundation

public struct FeedItem: Codable, Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: URL

    public init(id: UUID, description: String?, location: String?, imageURL: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }

    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case description = "description"
        case location = "location"
        case imageURL = "image"
    }
}
