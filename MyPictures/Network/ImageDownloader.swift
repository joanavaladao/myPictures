//
//  ImageDownload.swift
//  MyPictures
//
//  Created by Joana Valadao on 2025-08-27.
//

import Foundation

struct ImageDownloaded {
    let data: Data
    let duration: TimeInterval
    let downloadedAt: Date
}

protocol ImageDownloaderProtocol {
    func download(from imageURL: String, urlSession: URLSession) async throws -> ImageDownloaded?
}

final class ImageDownloader: ImageDownloaderProtocol {
    func download(from imageURL: String, urlSession: URLSession) async throws -> ImageDownloaded? {
        guard let url = URL(string: imageURL)
        else {
            throw URLError(.badURL)
        }

        let start = CFAbsoluteTimeGetCurrent()
        let (data, response) = try await urlSession.data(from: url)
        let duration = CFAbsoluteTimeGetCurrent() - start
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return ImageDownloaded(data: data, duration: duration, downloadedAt: Date())
    }
}
