//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge
import CoreData

class CoreDataFeedStore: FeedStore {
	let storeDataModelKey = "CoreDataFeedStore"
	let cacheEntityKey = "CoreDataFeedCache"
	static let feedImageEntityKey = "CoreDataFeedImage"

	var context: NSManagedObjectContext { persistentContainer!.viewContext }
	lazy var persistentContainer: NSPersistentContainer? = {

		guard let model = NSManagedObjectModel(contentsOf: Bundle(for: CoreDataFeedStore.self).url(forResource: storeDataModelKey, withExtension: "momd")!) else { return nil }

		let container = NSPersistentContainer(name: storeDataModelKey, managedObjectModel: model)
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

	func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		let fetchReqeust: NSFetchRequest<CoreDataFeedCache> = NSFetchRequest(entityName: cacheEntityKey)

		let fetchResult = try! context.fetch(fetchReqeust)
		if let cache = fetchResult.first {
			context.delete(cache)
		}
		completion(nil)
	}

	func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		deleteCachedFeed { _ in }

		let cacheEntity = NSEntityDescription.entity(forEntityName: cacheEntityKey, in: self.context)
		let cache = NSManagedObject(entity: cacheEntity!, insertInto: self.context) as! CoreDataFeedCache

		feed.forEach { cache.addToFeedItems($0.toEntity(context: context)) }

		cache.timestamp = timestamp

		try! self.context.save()

		completion(nil)
	}

	func retrieve(completion: @escaping RetrievalCompletion) {
		let request = NSFetchRequest<NSFetchRequestResult>(entityName: cacheEntityKey)

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

extension CoreDataFeedImage {
	func toLocal() -> LocalFeedImage {
		LocalFeedImage(id: id!, description: descriptionText, location: location, url: url!)
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
		let sut = try makeSUT()

		assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
	}
	
	func test_insert_deliversNoErrorOnNonEmptyCache() throws {
		let sut = try makeSUT()

		assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
	}
	
	func test_insert_overridesPreviouslyInsertedCacheValues() throws {
		let sut = try makeSUT()

		assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
	}
	
	func test_delete_deliversNoErrorOnEmptyCache() throws {
		let sut = try makeSUT()

		assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
	}
	
	func test_delete_hasNoSideEffectsOnEmptyCache() throws {
		let sut = try makeSUT()

		assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
	}
	
	func test_delete_deliversNoErrorOnNonEmptyCache() throws {
		let sut = try makeSUT()

		assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
	}
	
	func test_delete_emptiesPreviouslyInsertedCache() throws {
		let sut = try makeSUT()

		assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
	}
	
	func test_storeSideEffects_runSerially() throws {
		let sut = try makeSUT()

		assertThatSideEffectsRunSerially(on: sut)
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
