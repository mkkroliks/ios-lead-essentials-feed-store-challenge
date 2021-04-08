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
public class CoreDataFeedImage: NSManagedObject {
	@NSManaged public var descriptionText: String?
	@NSManaged public var id: UUID
	@NSManaged public var location: String?
	@NSManaged public var url: URL

	func toLocal() -> LocalFeedImage {
		return LocalFeedImage(id: id, description: descriptionText, location: location, url: url)
	}
}
