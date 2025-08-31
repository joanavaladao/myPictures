//
//  ImagePersistence.swift
//  MyPictures
//
//  Created by Joana Valadao on 2025-08-28.
//

import CoreData
import UIKit

struct ImageItem {
    var uuid: UUID
    var filePath: String
    var author: String?
    var order: Int
    var downloadDuration: TimeInterval?
    var downloadedAt: Date?
    
    init(from savedImage: SavedImage) {
        uuid = savedImage.uuid ?? UUID()
        filePath = savedImage.localFilePath ?? ""
        author = savedImage.author
        order = Int(savedImage.order)
        downloadDuration = savedImage.downloadDuration
        downloadedAt = savedImage.downloadedAt
    }
    
    func loadImageData(fileManager: FileManager = .default) throws -> Data? {
        let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filePath)
        return try Data(contentsOf: url)
    }
}

typealias ImageOrdering = [UUID: Int32]

protocol ImagePersistenceProtocol {
    @discardableResult
    func save(_ imageData: Data,
              author: String,
              downloadDuration: TimeInterval,
              downloadedAt: Date,
              downloadURL: String,
              imageURL: String,
              cloudID: String?) async throws -> ImageItem
    
    func delete(uuids: [UUID]) async throws
    
    func fetchAll() async throws -> [ImageItem]
    
    func updateOrder(_ ordering: ImageOrdering) async throws
}

class ImagePersistence: ImagePersistenceProtocol {
    private let container: NSPersistentContainer
    private var backgroundContext: NSManagedObjectContext
    private let fileDirectory: URL
    private let imagesDirectory = "images"
    private let fileManager: FileManager

    init(model: String = "MyPictures",
         fileManager: FileManager = FileManager.default) {
        
        // CoreData
        container = NSPersistentContainer(name: model)
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                // TODO: handle error
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext = container.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // FileManager
        self.fileManager = fileManager
        let baseDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileDirectory = baseDir.appendingPathComponent(imagesDirectory, isDirectory: true)
        try? fileManager.createDirectory(at: fileDirectory, withIntermediateDirectories: true)
    }
    
    @discardableResult
    func save(_ imageData: Data,
              author: String,
              downloadDuration: TimeInterval,
              downloadedAt: Date,
              downloadURL: String,
              imageURL: String,
              cloudID: String?) async throws -> ImageItem {
        
        let imageUUID = UUID()
        
        // Saving image in disk
        let fileURL = fileDirectory.appendingPathComponent(imageUUID.uuidString)
        try imageData.write(to: fileURL)
        
        return try await backgroundContext.perform {
            let request: NSFetchRequest<SavedImage> = SavedImage.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: false)]
            let order = try self.backgroundContext.fetch(request).first?.order ?? 0
            
            let newImage = SavedImage(context: self.backgroundContext)
            newImage.uuid = imageUUID
            newImage.author = author
            newImage.cloudID = cloudID
            newImage.downloadURL = downloadURL
            newImage.imageURL = imageURL
            newImage.downloadedAt = downloadedAt
            newImage.downloadDuration = downloadDuration
            newImage.downloadDuration = downloadDuration
            newImage.localFilePath = "\(self.imagesDirectory)/\(imageUUID.uuidString)"
            newImage.order = Int32(order+1)
            
            try self.backgroundContext.save()
            
            return ImageItem(from: newImage)
        }
    }
    
    func delete(uuids: [UUID]) async throws {
        // CoreData
        try await backgroundContext.perform {
            let request: NSFetchRequest<SavedImage> = SavedImage.fetchRequest()
            request.predicate = NSPredicate(format: "uuid IN %@", uuids)
            let objects = try self.backgroundContext.fetch(request)
            for object in objects {
                self.backgroundContext.delete(object)
            }
            try self.backgroundContext.save()
        }
        
        // FileManager
        for uuid in uuids {
            let url = fileDirectory.appendingPathComponent(uuid.uuidString)
            try fileManager.removeItem(at: url)
        }
    }
    
    func fetchAll() async throws -> [ImageItem] {
        try await container.viewContext.perform {
            let request: NSFetchRequest<SavedImage> = SavedImage.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
            let objects = try self.backgroundContext.fetch(request)
            return objects.map { .init(from: $0) }
        }
    }
    
    func updateOrder(_ ordering: ImageOrdering) async throws {
        guard !ordering.isEmpty else { return }
        
        try await backgroundContext.perform {
            let request: NSFetchRequest<SavedImage> = SavedImage.fetchRequest()
            request.predicate = NSPredicate(format: "uuid IN %@", Array(ordering.keys))
            let objects = try self.backgroundContext.fetch(request)
            
            for object in objects {
                if let uuid = object.uuid {
                    object.order = Int32(ordering[uuid] ?? 0)
                }
            }
            try self.backgroundContext.save()
        }
    }
}
