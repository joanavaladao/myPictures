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

protocol ImageServiceProtocol {
    func addRandomImage() async throws -> ImageItem?
    func loadAllImages() async throws -> [ImageItem]
    func delete(uuids: [UUID]) async throws
    func update(imageOrdering: ImageOrdering) async throws
}

final class ImageService: ImageServiceProtocol {
    private let imageListAPI: ImageListAPIProtocol
    private let imageDownloader: ImageDownloaderProtocol
    private let persistence: ImagePersistenceProtocol
    private let urlString: String
    private let page: Int
    private let itemsPerPage: Int
    private let urlSession: URLSession
    
    init(imageListAPI: ImageListAPIProtocol = ImageListAPI(),
         imageDownloader: ImageDownloaderProtocol = ImageDownloader(),
         persistence: ImagePersistenceProtocol = ImagePersistence(),
         urlString: String = "https://picsum.photos/v2/list",
         page: Int = 1,
         itemsPerPage: Int = 30,
         with urlSession: URLSession = URLSession.shared) {
        self.imageListAPI = imageListAPI
        self.imageDownloader = imageDownloader
        self.persistence = persistence
        self.urlString = urlString
        self.page = page
        self.itemsPerPage = itemsPerPage
        self.urlSession = urlSession
    }
    
    func addRandomImage() async throws -> ImageItem? {

        try Task.checkCancellation()
        let list = try await imageListAPI.fetchList(page: page, limit: itemsPerPage, urlString: urlString, urlSession: urlSession)

        try Task.checkCancellation()
        guard !list.isEmpty,
              let randomElement = list.randomElement(),
              let imageDownloaded = try await imageDownloader.download(from: randomElement.download_url, urlSession: urlSession)
        else {
            return nil
        }

        let image = try await persistence.save(imageDownloaded.data,
                                               author: randomElement.author,
                                               downloadDuration: imageDownloaded.duration,
                                               downloadedAt: imageDownloaded.downloadedAt,
                                               downloadURL: randomElement.download_url,
                                               imageURL: randomElement.url,
                                               cloudID: randomElement.id)
        return image
    }
    
    func loadAllImages() async throws -> [ImageItem] {
        try await persistence.fetchAll()
    }
    
    func delete(uuids: [UUID]) async throws {
        try await persistence.delete(uuids: uuids)
    }
    
    func update(imageOrdering: ImageOrdering) async throws {
        try await persistence.updateOrder(imageOrdering)
    }
}
