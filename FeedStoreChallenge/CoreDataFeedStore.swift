//
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import CoreData

public final class CoreDataFeedStore: FeedStore {
	private static let modelName = "CoreDataFeedStore"
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
		let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreDataFeedCache")
		let result = try! context.fetch(request)
		if let cache = result.first as? CoreDataFeedCache {
			let feed = cache.feedItems?.map { feedImage -> LocalFeedImage in
				let image = feedImage as! CoreDataFeedImage
				return LocalFeedImage(id: image.id!, description: image.descriptionText, location: image.location, url: image.url!)
			}
			completion(.found(feed: feed!, timestamp: cache.timestamp!))
		} else {
			completion(.empty)
		}
	}

	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		let cacheEntity = NSEntityDescription.entity(forEntityName: "CoreDataFeedCache", in: self.context)
		let cache = NSManagedObject(entity: cacheEntity!, insertInto: self.context) as! CoreDataFeedCache

		for feedItem in feed {
			let localFeedImageEntity = NSEntityDescription.entity(forEntityName: "CoreDataFeedImage", in: self.context)
			let coreDataFeed = NSManagedObject(entity: localFeedImageEntity!, insertInto: self.context) as! CoreDataFeedImage
			coreDataFeed.setValue(feedItem.id, forKey: "id")
			if let description = feedItem.description {
				coreDataFeed.setValue(description, forKey: "descriptionText")
			}
			if let location = feedItem.location {
				coreDataFeed.setValue(location, forKey: "location")
			}
			coreDataFeed.setValue(feedItem.url, forKey: "url")

			cache.addToFeedItems(coreDataFeed)
		}

		cache.timestamp = timestamp

		try! self.context.save()

		completion(nil)
	}

	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		fatalError("Must be implemented")
	}
}
