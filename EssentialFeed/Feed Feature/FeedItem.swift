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
}
