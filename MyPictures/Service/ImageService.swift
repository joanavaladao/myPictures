//
//  ImageService.swift
//  MyPictures
//
//  Created by Joana Valadao on 2025-08-28.
//

import Foundation

enum SortOption {
    case author
    case downloadedAt
    case manual
}

final class ImageService {
    private let imageListAPI: ImageListAPIProtocol
    private let imageDownloader: ImageDownloaderProtocol
    private let persistence: ImagePersistenceProtocol
    
    init(imageListAPI: ImageListAPIProtocol = ImageListAPI(),
         imageDownloader: ImageDownloaderProtocol = ImageDownloader(),
         persistence: ImagePersistenceProtocol = ImagePersistence()) {
        self.imageListAPI = imageListAPI
        self.imageDownloader = imageDownloader
        self.persistence = persistence
    }
    
    func addRandomImage(from path: String = "https://picsum.photos/v2/list",
                        page: Int = 1,
                        itemsPerPage: Int = 30,
                        urlSession: URLSession = URLSession.shared) async throws -> ImageItem? {

        try Task.checkCancellation()
        let list = try await imageListAPI.fetchList(page: page, limit: itemsPerPage, urlString: path, urlSession: urlSession)

        try Task.checkCancellation()
        guard !list.isEmpty,
              let randomElement = list.randomElement(),
              let imageData = try await imageDownloader.download(from: randomElement.download_url, urlSession: urlSession)
        else {
            return nil
        }

        let image = try await persistence.save(imageData.data,
                                               author: randomElement.author,
                                               downloadDuration: imageData.duration,
                                               downloadedAt: imageData.downloadedAt,
                                               downloadURL: randomElement.download_url,
                                               imageURL: randomElement.url,
                                               cloudID: randomElement.id)
        return image
    }
    
    func loadAllImages() async throws -> [ImageItem] {
        try await persistence.fetchAll(sortedByOrder: true)
    }
    
    func delete(uuid: UUID) async throws {
        try await persistence.delete(imageUUID: uuid)
    }
    
    func update(images: [ImageItem], sortOption: SortOption, ascending: Bool) async throws -> [ImageItem] {
        var newSortedImages: [ImageItem]
        let date = Date()
        switch sortOption {
        case .author:
            newSortedImages = ascending ? images.sorted { ($0.author ?? "" < $1.author ?? "") && ($0.uuid < $1.uuid) } : images.sorted { ($0.author ?? "" > $1.author ?? "") && ($0.uuid > $1.uuid) }
        case .downloadedAt:
            newSortedImages = ascending ? images.sorted { ($0.downloadedAt ?? date < $1.downloadedAt ?? date) && ($0.uuid < $1.uuid) } : images.sorted { ($0.downloadedAt ?? date > $1.downloadedAt ?? date) && ($0.uuid > $1.uuid) }
        case .manual:
            return images
        }
        
        var imageOrdering: ImageOrdering = [:]
        for i in 0..<newSortedImages.count {
            if newSortedImages[i].order != i {
                imageOrdering[newSortedImages[i].uuid.uuidString] = i
                newSortedImages[i].order = i
            }
        }
        
        try await persistence.updateOrder(imageOrdering)

        return newSortedImages
    }
}
