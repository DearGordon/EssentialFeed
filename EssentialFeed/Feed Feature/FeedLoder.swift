//
//  FeedLoder.swift
//  NetworkModule
//
//  Created by Gordon Feng on 28/5/21.
//

import Foundation

protocol FeedLoader {
    func load(completion: (Result<FeedItem, Error>) -> Void)
}

class RemoteFeedLoader: FeedLoader {

    func load(completion: (Result<FeedItem, Error>) -> Void) {

    }
}
