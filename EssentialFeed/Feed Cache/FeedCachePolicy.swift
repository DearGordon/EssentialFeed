//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Gordon Feng on 1/7/21.
//

import Foundation

internal final class FeedCachePolicy {
    private init() {}

    private static let maxCacheAgeInDays: Int = 7
    private static let calendar = Calendar(identifier: .gregorian)

    internal static func validDate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return date < maxCacheAge
    }
}
