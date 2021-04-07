//
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import CoreData

public final class CoreDataFeedStore: FeedStore {
	private static let modelName = "CoreDataFeedStore"
	private let cacheEntityKey = "CoreDataFeedCache"
	static let feedImageEntityKey = "CoreDataFeedImage"

	private static let model = NSManagedObjectModel(name: modelName, in: Bundle(for: CoreDataFeedStore.self))

	private let container: NSPersistentContainer
	private let context: NSManagedObjectContext

	struct ModelNotFound: Error {
		let modelName: String
	}

	public init(storeURL: URL) throws {
		guard let model = CoreDataFeedStore.model else {
			throw ModelNotFound(modelName: CoreDataFeedStore.modelName)
		}

		container = try NSPersistentContainer.load(
			name: CoreDataFeedStore.modelName,
			model: model,
			url: storeURL
		)
		context = container.newBackgroundContext()
	}

	public func retrieve(completion: @escaping RetrievalCompletion) {
		let request = NSFetchRequest<NSFetchRequestResult>(entityName: cacheEntityKey)
		do {
			let result = try context.fetch(request)
			if let cache = result.first as? CoreDataFeedCache {
				let feed = cache.feedItems?
					.compactMap { $0 as? CoreDataFeedImage }
					.map { $0.toLocal() }
				completion(.found(feed: feed!, timestamp: cache.timestamp!))
			} else {
				completion(.empty)
			}
		} catch {
			completion(.failure(error))
		}
	}

	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		let cacheEntity = NSEntityDescription.entity(forEntityName: cacheEntityKey, in: self.context)
		let cache = NSManagedObject(entity: cacheEntity!, insertInto: self.context) as! CoreDataFeedCache

		feed.forEach { cache.addToFeedItems($0.toEntity(context: context)) }

		cache.timestamp = timestamp

		try! self.context.save()

		completion(nil)
	}

	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		fatalError("Must be implemented")
	}
}

private extension CoreDataFeedImage {
	func toLocal() -> LocalFeedImage {
		LocalFeedImage(id: id!, description: descriptionText, location: location, url: url!)
	}
}

private extension LocalFeedImage {
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
