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
		do {
			try deleteCache()
			completion(nil)
		} catch {
			completion(error)
		}
	}

	func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		do {
			try deleteCache()
			try CoreDataFeedCache.insert(feed: feed, timestamp: timestamp, context: self.context)
			try self.context.save()
			completion(nil)
		} catch {
			completion(error)
		}
	}

	func retrieve(completion: @escaping RetrievalCompletion) {
		do {
			if
				let cache = try CoreDataFeedCache.fetch(context: context),
				let feedItems = cache.feedItems,
				let timestamp = cache.timestamp {

				let feed = mapToLocalFeed(feedItems: feedItems)
				completion(.found(feed: feed, timestamp: timestamp))
			} else {
				completion(.empty)
			}
		} catch {
			completion(.failure(error))
		}
	}

	private func deleteCache() throws {
		try persistentContainer.persistentStoreCoordinator.execute(CoreDataFeedCache.deleteRequest(), with: context)
	}

	private func mapToLocalFeed(feedItems: NSOrderedSet) -> [LocalFeedImage] {
		feedItems
			.compactMap { $0 as? CoreDataFeedImage }
			.compactMap { $0.toLocal() }
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
	enum Error: Swift.Error {
		case entityNotFound
		case managedObjectCreationFailure
	}

	var feedImageEntityKey: String { "CoreDataFeedImage" }

	func toEntity(context: NSManagedObjectContext) throws -> CoreDataFeedImage {
		guard let localFeedImageEntity = NSEntityDescription.entity(forEntityName: self.feedImageEntityKey, in: context) else {
			throw Error.entityNotFound
		}
		guard let coreDataFeed = NSManagedObject(entity: localFeedImageEntity, insertInto: context) as? CoreDataFeedImage else {
			throw Error.managedObjectCreationFailure
		}

		coreDataFeed.id = id
		coreDataFeed.descriptionText = description
		coreDataFeed.location = location
		coreDataFeed.url = url

		return coreDataFeed
	}
}

extension CoreDataFeedCache {
	enum Error: Swift.Error {
		case entityNotFound
		case managedObjectCreationFailure
	}

	static var cacheEntityKey: String { "CoreDataFeedCache" }

	public static func createFetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
		return NSFetchRequest<NSFetchRequestResult>(entityName: self.cacheEntityKey)
	}

	static func deleteRequest() -> NSBatchDeleteRequest {
		let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: self.cacheEntityKey)
		return NSBatchDeleteRequest(fetchRequest: fetchRequest)
	}

	private static func create(context: NSManagedObjectContext) throws -> CoreDataFeedCache {
		guard let cacheEntity = NSEntityDescription.entity(forEntityName: self.cacheEntityKey, in: context) else {
			throw Error.entityNotFound
		}
		guard let cache = NSManagedObject(entity: cacheEntity, insertInto: context) as? CoreDataFeedCache else {
			throw Error.managedObjectCreationFailure
		}
		return cache
	}

	static func insert(feed: [LocalFeedImage], timestamp: Date, context: NSManagedObjectContext) throws {
		let cache = try create(context: context)
		try cache.fill(with: feed, timestamp: timestamp, context: context)
	}

	private func fill(with feed: [LocalFeedImage], timestamp: Date, context: NSManagedObjectContext) throws {
		try feed.forEach {
			addToFeedItems(try $0.toEntity(context: context))
		}
		self.timestamp = timestamp
	}

	static func fetch(context: NSManagedObjectContext) throws -> CoreDataFeedCache? {
		let result = try context.fetch(CoreDataFeedCache.createFetchRequest())
		return result.first as? CoreDataFeedCache
	}
}

extension CoreDataFeedImage {
	func toLocal() -> LocalFeedImage? {
		guard
			let id = id,
			let url = url
		else {
			return nil
		}
		return LocalFeedImage(id: id, description: descriptionText, location: location, url: url)
	}
}
