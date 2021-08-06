//
//  FeedLoder.swift
//  NetworkModule
//
//  Created by Gordon Feng on 28/5/21.
//

import Foundation

public protocol FeedLoader {
    func load(completion: @escaping ((Result<[FeedImage], Error>) -> Void))
}

