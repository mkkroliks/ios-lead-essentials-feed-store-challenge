//
//  CoreDataFeedCache.swift
//  FeedStoreChallenge
//
//  Created by Maciej Krolikowski on 08/04/2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CoreDataFeedCache)
class CoreDataFeedCache: NSManagedObject {
	@NSManaged var timestamp: Date
	@NSManaged var feedItems: NSOrderedSet
}

extension CoreDataFeedCache {
	static func deleteRequest() -> NSBatchDeleteRequest {
		return NSBatchDeleteRequest(fetchRequest: CoreDataFeedCache.fetchRequest())
	}

	static func insert(feed: [LocalFeedImage], timestamp: Date, context: NSManagedObjectContext) {
		let cache = self.init(context: context)
		cache.feedItems = NSOrderedSet(array: feed.map { $0.toEntity(context: context) })
		cache.timestamp = timestamp
	}

	static func fetch(context: NSManagedObjectContext) throws -> CoreDataFeedCache? {
		let result = try context.fetch(CoreDataFeedCache.fetchRequest())
		return result.first as? CoreDataFeedCache
	}

	static func fetchRequest() -> NSFetchRequest<CoreDataFeedCache> {
		return NSFetchRequest<CoreDataFeedCache>(entityName: "CoreDataFeedCache")
	}
}
