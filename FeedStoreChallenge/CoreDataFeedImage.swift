//
//  CoreDataFeedImage+CoreDataProperties.swift
//  FeedStoreChallenge
//
//  Created by Maciej Krolikowski on 08/04/2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CoreDataFeedImage)
class CoreDataFeedImage: NSManagedObject {
	@NSManaged var descriptionText: String?
	@NSManaged var id: UUID
	@NSManaged var location: String?
	@NSManaged var url: URL

	func toLocal() -> LocalFeedImage {
		return LocalFeedImage(id: id, description: descriptionText, location: location, url: url)
	}
}
