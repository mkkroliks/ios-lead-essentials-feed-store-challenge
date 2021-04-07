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
	let cacheEntityKey = "CoreDataFeedCache"
	static let feedImageEntityKey = "CoreDataFeedImage"

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
			let cacheEntity = NSEntityDescription.entity(forEntityName: self.cacheEntityKey, in: self.context)
			let cache = NSManagedObject(entity: cacheEntity!, insertInto: self.context) as! CoreDataFeedCache

			feed.forEach { cache.addToFeedItems($0.toEntity(context: self.context)) }

			cache.timestamp = timestamp

			try! self.context.save()

			completion(nil)
		}
	}

	func retrieve(completion: @escaping RetrievalCompletion) {
		let request = NSFetchRequest<NSFetchRequestResult>(entityName: self.cacheEntityKey)

		let result = try! context.fetch(request)
		if let cache = result.first as? CoreDataFeedCache {
			let feed = cache.feedItems?
				.compactMap { $0 as? CoreDataFeedImage }
				.map { $0.toLocal() }
			completion(.found(feed: feed!, timestamp: cache.timestamp!))
		} else {
			completion(.empty)
		}
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
	func toEntity(context: NSManagedObjectContext) -> CoreDataFeedImage {
		let localFeedImageEntity = NSEntityDescription.entity(forEntityName: CoreDataFeedStore.feedImageEntityKey, in: context)

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

	static func deleteRequest() -> NSBatchDeleteRequest {
		let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: self.cacheEntityKey)
		return NSBatchDeleteRequest(fetchRequest: fetchRequest)
	}
}

extension CoreDataFeedImage {
	func toLocal() -> LocalFeedImage {
		LocalFeedImage(id: id!, description: descriptionText, location: location, url: url!)
	}
}
