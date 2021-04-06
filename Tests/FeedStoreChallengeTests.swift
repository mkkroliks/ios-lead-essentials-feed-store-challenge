//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge
import CoreData

class CoreDataFeedStore: FeedStore {
	var context: NSManagedObjectContext { persistentContainer!.viewContext }

	lazy var persistentContainer: NSPersistentContainer? = {

		guard let model = NSManagedObjectModel(contentsOf: Bundle(for: CoreDataFeedStore.self).url(forResource: "CoreDataFeedStore", withExtension: "momd")!) else { return nil }

		let container = NSPersistentContainer(name: "CoreDataFeedStore", managedObjectModel: model)
		let description = NSPersistentStoreDescription(url: URL(fileURLWithPath: "dev/null"))
		description.type = NSInMemoryStoreType
		container.persistentStoreDescriptions = [description]

		container.loadPersistentStores { description, error in
			if let error = error {
				fatalError("Unable to load persistent stores: \(error)")
			}
		}
		return container
	}()

	func deleteCachedFeed(completion: @escaping DeletionCompletion) {}

	func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
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

	func retrieve(completion: @escaping RetrievalCompletion) {
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
}

class FeedStoreChallengeTests: XCTestCase, FeedStoreSpecs {
	
	//  ***********************
	//
	//  Follow the TDD process:
	//
	//  1. Uncomment and run one test at a time (run tests with CMD+U).
	//  2. Do the minimum to make the test pass and commit.
	//  3. Refactor if needed and commit again.
	//
	//  Repeat this process until all tests are passing.
	//
	//  ***********************
	
	func test_retrieve_deliversEmptyOnEmptyCache() throws {
		let sut = try makeSUT()

		assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
	}
	
	func test_retrieve_hasNoSideEffectsOnEmptyCache() throws {
		let sut = try makeSUT()

		assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
	}
	
	func test_retrieve_deliversFoundValuesOnNonEmptyCache() throws {
		let sut = try makeSUT()

		assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
	}
	
	func test_retrieve_hasNoSideEffectsOnNonEmptyCache() throws {
		let sut = try makeSUT()

		assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
	}
	
	func test_insert_deliversNoErrorOnEmptyCache() throws {
//		let sut = try makeSUT()
//
//		assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
	}
	
	func test_insert_deliversNoErrorOnNonEmptyCache() throws {
//		let sut = try makeSUT()
//
//		assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
	}
	
	func test_insert_overridesPreviouslyInsertedCacheValues() throws {
//		let sut = try makeSUT()
//
//		assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
	}
	
	func test_delete_deliversNoErrorOnEmptyCache() throws {
//		let sut = try makeSUT()
//
//		assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
	}
	
	func test_delete_hasNoSideEffectsOnEmptyCache() throws {
//		let sut = try makeSUT()
//
//		assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
	}
	
	func test_delete_deliversNoErrorOnNonEmptyCache() throws {
//		let sut = try makeSUT()
//
//		assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
	}
	
	func test_delete_emptiesPreviouslyInsertedCache() throws {
//		let sut = try makeSUT()
//
//		assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
	}
	
	func test_storeSideEffects_runSerially() throws {
//		let sut = try makeSUT()
//
//		assertThatSideEffectsRunSerially(on: sut)
	}
	
	// - MARK: Helpers
	
	private func makeSUT() throws -> FeedStore {
		CoreDataFeedStore()
	}
	
}

//  ***********************
//
//  Uncomment the following tests if your implementation has failable operations.
//
//  Otherwise, delete the commented out code!
//
//  ***********************

//extension FeedStoreChallengeTests: FailableRetrieveFeedStoreSpecs {
//
//	func test_retrieve_deliversFailureOnRetrievalError() throws {
////		let sut = try makeSUT()
////
////		assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
//	}
//
//	func test_retrieve_hasNoSideEffectsOnFailure() throws {
////		let sut = try makeSUT()
////
////		assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
//	}
//
//}

//extension FeedStoreChallengeTests: FailableInsertFeedStoreSpecs {
//
//	func test_insert_deliversErrorOnInsertionError() throws {
////		let sut = try makeSUT()
////
////		assertThatInsertDeliversErrorOnInsertionError(on: sut)
//	}
//
//	func test_insert_hasNoSideEffectsOnInsertionError() throws {
////		let sut = try makeSUT()
////
////		assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
//	}
//
//}

//extension FeedStoreChallengeTests: FailableDeleteFeedStoreSpecs {
//
//	func test_delete_deliversErrorOnDeletionError() throws {
////		let sut = try makeSUT()
////
////		assertThatDeleteDeliversErrorOnDeletionError(on: sut)
//	}
//
//	func test_delete_hasNoSideEffectsOnDeletionError() throws {
////		let sut = try makeSUT()
////
////		assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
//	}
//
//}
