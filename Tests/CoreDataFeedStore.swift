//
//  CoreDataFeedStore.swift
//  Tests
//
//  Created by Maciej Krolikowski on 07/04/2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import FeedStoreChallenge
import CoreData

class CoreDataFeedStore: FeedStore {
	var context: NSManagedObjectContext { persistentContainer.viewContext }
	let persistentContainer: NSPersistentContainer

	init(storeURL: URL? = nil, bundle: Bundle = .main) throws {
		persistentContainer = try NSPersistentContainer.loadAndReturn(storeURL: storeURL, bundle: bundle)
	}

	func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		try! persistentContainer.persistentStoreCoordinator.execute(CoreDataFeedCache.deleteRequest(), with: context)
		completion(nil)
	}

	func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		self.deleteCachedFeed { _ in
			CoreDataFeedCache.insert(feed: feed, timestamp: timestamp, context: self.context)
			try! self.context.save()
			completion(nil)
		}
	}

	func retrieve(completion: @escaping RetrievalCompletion) {
		if
			let cache = CoreDataFeedCache.fetch(context: context),
			let feedItems = cache.feedItems {

			let feed = mapToLocalFeed(feedItems: feedItems)
			completion(.found(feed: feed, timestamp: cache.timestamp!))
		} else {
			completion(.empty)
		}
	}

	private func mapToLocalFeed(feedItems: NSOrderedSet) -> [LocalFeedImage] {
		feedItems
			.compactMap { $0 as? CoreDataFeedImage }
			.map { $0.toLocal() }
	}
}

private extension NSPersistentContainer {
	enum Error: Swift.Error {
		case managedObjectModelNotFound
		case loadPersistentStoreFailure(Swift.Error)
	}

	static var storeDataModelKey: String { "CoreDataFeedStore" }

	static func loadAndReturn(storeURL: URL? = nil, bundle: Bundle = .main) throws -> NSPersistentContainer {
		guard
			let url = bundle.url(forResource: storeDataModelKey, withExtension: "momd"),
			let model = NSManagedObjectModel(contentsOf: url)
		else {
			throw Error.managedObjectModelNotFound
		}

		let container = NSPersistentContainer(name: storeDataModelKey, managedObjectModel: model)
		if let storeURL = storeURL {
			let description = NSPersistentStoreDescription(url: storeURL)
			container.persistentStoreDescriptions = [description]
		}

		var loadPersistentStoreError: Swift.Error?
		container.loadPersistentStores { description, error in
			loadPersistentStoreError = error
		}

		if let loadPersistentStoreError = loadPersistentStoreError {
			throw Error.loadPersistentStoreFailure(loadPersistentStoreError)
		}

		return container
	}
}

extension LocalFeedImage {
	var feedImageEntityKey: String { "CoreDataFeedImage" }

	func toEntity(context: NSManagedObjectContext) -> CoreDataFeedImage {
		let localFeedImageEntity = NSEntityDescription.entity(forEntityName: self.feedImageEntityKey, in: context)

		let coreDataFeed = NSManagedObject(entity: localFeedImageEntity!, insertInto: context) as! CoreDataFeedImage
		coreDataFeed.id = id
		coreDataFeed.descriptionText = description
		coreDataFeed.location = location
		coreDataFeed.url = url

		return coreDataFeed
	}
}

extension CoreDataFeedCache {
	static var cacheEntityKey: String { "CoreDataFeedCache" }

	public static func createFetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
		return NSFetchRequest<NSFetchRequestResult>(entityName: self.cacheEntityKey)
	}

	static func deleteRequest() -> NSBatchDeleteRequest {
		let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: self.cacheEntityKey)
		return NSBatchDeleteRequest(fetchRequest: fetchRequest)
	}

	private static func create(context: NSManagedObjectContext) -> CoreDataFeedCache {
		let cacheEntity = NSEntityDescription.entity(forEntityName: self.cacheEntityKey, in: context)
		return NSManagedObject(entity: cacheEntity!, insertInto: context) as! CoreDataFeedCache
	}

	static func insert(feed: [LocalFeedImage], timestamp: Date, context: NSManagedObjectContext) {
		let cache = create(context: context)
		cache.fill(with: feed, timestamp: timestamp, context: context)
	}

	private func fill(with feed: [LocalFeedImage], timestamp: Date, context: NSManagedObjectContext) {
		feed.forEach {
			addToFeedItems($0.toEntity(context: context))
		}
		self.timestamp = timestamp
	}

	static func fetch(context: NSManagedObjectContext) -> CoreDataFeedCache? {
		let result = try! context.fetch(CoreDataFeedCache.createFetchRequest())
		return result.first as? CoreDataFeedCache
	}
}

extension CoreDataFeedImage {
	func toLocal() -> LocalFeedImage {
		LocalFeedImage(id: id!, description: descriptionText, location: location, url: url!)
	}
}
