//
//  FeedLoder.swift
//  NetworkModule
//
//  Created by Gordon Feng on 28/5/21.
//

import Foundation

protocol FeedLoader {
    func load(completion: @escaping ((Result<FeedItem, Error>) -> Void))
}

