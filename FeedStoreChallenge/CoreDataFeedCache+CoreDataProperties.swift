//
//  CoreDataFeedCache+CoreDataProperties.swift
//  FeedStoreChallenge
//
//  Created by Maciej Krolikowski on 08/04/2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//
//

import Foundation
import CoreData

extension CoreDataFeedCache {
	@nonobjc public class func fetchRequest() -> NSFetchRequest<CoreDataFeedCache> {
		return NSFetchRequest<CoreDataFeedCache>(entityName: "CoreDataFeedCache")
	}

	@NSManaged public var timestamp: Date
	@NSManaged public var feedItems: NSOrderedSet
}

// MARK: Generated accessors for feedItems
extension CoreDataFeedCache {
	@objc(insertObject:inFeedItemsAtIndex:)
	@NSManaged public func insertIntoFeedItems(_ value: CoreDataFeedImage, at idx: Int)

	@objc(removeObjectFromFeedItemsAtIndex:)
	@NSManaged public func removeFromFeedItems(at idx: Int)

	@objc(insertFeedItems:atIndexes:)
	@NSManaged public func insertIntoFeedItems(_ values: [CoreDataFeedImage], at indexes: NSIndexSet)

	@objc(removeFeedItemsAtIndexes:)
	@NSManaged public func removeFromFeedItems(at indexes: NSIndexSet)

	@objc(replaceObjectInFeedItemsAtIndex:withObject:)
	@NSManaged public func replaceFeedItems(at idx: Int, with value: CoreDataFeedImage)

	@objc(replaceFeedItemsAtIndexes:withFeedItems:)
	@NSManaged public func replaceFeedItems(at indexes: NSIndexSet, with values: [CoreDataFeedImage])

	@objc(addFeedItemsObject:)
	@NSManaged public func addToFeedItems(_ value: CoreDataFeedImage)

	@objc(removeFeedItemsObject:)
	@NSManaged public func removeFromFeedItems(_ value: CoreDataFeedImage)

	@objc(addFeedItems:)
	@NSManaged public func addToFeedItems(_ values: NSOrderedSet)

	@objc(removeFeedItems:)
	@NSManaged public func removeFromFeedItems(_ values: NSOrderedSet)
}

extension CoreDataFeedCache: Identifiable {}
