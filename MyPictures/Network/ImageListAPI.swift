//
//  ImageListAPI.swift
//  MyPictures
//
//  Created by Joana Valadao on 2025-08-27.
//

import Foundation

struct PicsumInfo: Decodable {
    let id: String
    let author: String
    let width: Int
    let height: Int
    let url: String
    let download_url: String
}

protocol ImageListAPIProtocol {
    func fetchList(page: Int, limit: Int, urlString: String, urlSession: URLSession) async throws -> [PicsumInfo]
}

final class ImageListAPI: ImageListAPIProtocol {
    func fetchList(page: Int, limit: Int, urlString: String, urlSession: URLSession = URLSession.shared) async throws -> [PicsumInfo] {
        guard var urlComponent = URLComponents(string: urlString) else {
            throw URLError(.badURL)
        }
        
        urlComponent.queryItems = [
            .init(name: "page", value: "\(page)"),
            .init(name: "limit", value: "\(limit)"),
        ]
        
        guard let url = urlComponent.url else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await urlSession.data(from: url)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([PicsumInfo].self, from: data)
    }
}
