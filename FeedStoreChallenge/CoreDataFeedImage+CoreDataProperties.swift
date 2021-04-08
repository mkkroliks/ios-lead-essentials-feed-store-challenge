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

extension CoreDataFeedImage {
	@nonobjc public class func fetchRequest() -> NSFetchRequest<CoreDataFeedImage> {
		return NSFetchRequest<CoreDataFeedImage>(entityName: "CoreDataFeedImage")
	}

	@NSManaged public var descriptionText: String?
	@NSManaged public var id: UUID
	@NSManaged public var location: String?
	@NSManaged public var url: URL
}

extension CoreDataFeedImage: Identifiable {}
