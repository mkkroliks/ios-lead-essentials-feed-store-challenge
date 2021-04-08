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
		context.perform {
			do {
				if
					let cache = try CoreDataFeedCache.fetch(context: self.context) {
					let feed = self.mapToLocalFeed(feedItems: cache.feedItems)
					completion(.found(feed: feed, timestamp: cache.timestamp))
				} else {
					completion(.empty)
				}
			} catch {
				completion(.failure(error))
			}
		}
	}

	private func deleteCache() throws {
		try context.execute(CoreDataFeedCache.deleteRequest())
	}

	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		context.perform {
			do {
				try self.deleteCache()
				CoreDataFeedCache.insert(feed: feed, timestamp: timestamp, context: self.context)
				try self.context.save()
				completion(nil)
			} catch {
				self.context.rollback()
				completion(error)
			}
		}
	}

	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		context.perform {
			do {
				try self.deleteCache()
				try self.context.save()
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}

	private func mapToLocalFeed(feedItems: NSOrderedSet) -> [LocalFeedImage] {
		feedItems
			.compactMap { $0 as? CoreDataFeedImage }
			.compactMap { $0.toLocal() }
	}
}
