//
//  FeedLoder.swift
//  NetworkModule
//
//  Created by Gordon Feng on 28/5/21.
//

import Foundation

//public typealias LoadFeedResult = (Result<[FeedItem], Error>)

//extension LoadFeedResult where Error: Equatable {}

public protocol FeedLoader {
    func load(completion: @escaping ((Result<[FeedItem], Error>) -> Void))
}

