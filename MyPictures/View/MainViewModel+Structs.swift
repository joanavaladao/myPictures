//
//  MainViewModel+Structs.swift
//  MyPictures
//
//  Created by Joana Valadao on 2025-09-01.
//

import UIKit

// MARK: Structs and Enums
extension MainViewModel {
    struct ImageInfo: Hashable {
        let uuid: UUID
        let author: String
        let image: UIImage?
        var order: Int
        let downloadedAt: Date
        let isLoading: Bool
        
        init(from item: ImageItem) {
            uuid = item.uuid
            author = item.author ?? String(localized: "Unknown Author")
            order = item.order
            downloadedAt = item.downloadedAt ?? Date(timeIntervalSinceReferenceDate: -123456789.0)
            isLoading = false
            
            var image = UIImage(systemName: "photo.on.rectangle.fill")

            do {
                if let imageData = try item.loadImageData() as Data? {
                    image = UIImage(data: imageData)
                }
            } catch {
                print("Log error: \(error)")
            }
            
            self.image = image
        }
        
        init(uuid: UUID, author: String = "", image: UIImage? = nil, order: Int, downloadedAt: Date? = nil, isLoading: Bool) {
            self.uuid = uuid
            self.author = author
            self.image = image
            self.order = order
            self.downloadedAt = downloadedAt ?? Date(timeIntervalSinceReferenceDate: -123456789.0)
            self.isLoading = isLoading
        }
        
        func dateString() -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM-dd-yyyy HH:mm"
            return dateFormatter.string(from: downloadedAt)
        }
    }
    
    enum DataState {
        case empty
        case refresh([ImageInfo])
        case failed(String)
    }
}

struct ReportData: Hashable {
    let total: Int
    let imagesToday: Int
    let uniqueAuthors: Int
    let imagesByAuthor: [String: Int]
}

struct ReportRow: Hashable {
    var title: String
    var detail: String
}

enum ReportSection: Int {
    case summary
    case authors
    
    var title: String {
        switch self {
        case .summary:
            return String(localized: "Summary")
        case .authors:
            return String(localized: "Authors")
        }
    }
}
