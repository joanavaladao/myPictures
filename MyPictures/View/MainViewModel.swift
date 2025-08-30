//
//  MainViewModel.swift
//  MyPictures
//
//  Created by Joana Valadao on 2025-08-29.
//

import UIKit

final class MainViewModel {
    struct ImageInfo: Hashable {
        let uuid: UUID
        let author: String
        let image: UIImage?
        var order: Int
        let downloadedAt: Date
        let isLoading: Bool
        
        init(from item: ImageItem) {
            uuid = item.uuid
            author = item.author ?? "Unknown Author"
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
    }
    
    enum DataState {
        case empty
        case refresh([ImageInfo])
        case failed(Error)
    }    
    
    private let service: ImageServiceProtocol
    private var items: [ImageInfo] = []
    private var sortSelected: SortOption = .manual
    private var isAscending: Bool = true
    var onChange: ((DataState) -> Void)?
    
    init(service: ImageServiceProtocol = ImageService()) {
        self.service = service
    }
    
    func loadImages() {
        Task {
            do {
                let savedImages = try await self.service.loadAllImages()
                items = savedImages.map { .init(from: $0) }
                await emitState()
            } catch {
                onChange?(.failed(error))
            }
        }
    }

    func addNewImageWithSpinner() {
        
        let placeholderID = UUID()
        let placeholder = ImageInfo(uuid: placeholderID, order: items.count, isLoading: true)
        items.append(placeholder)
        
        Task {
            await emitState()
            do {
                if let newImage = try await service.addRandomImage() {
                    let newItem = ImageInfo(from: newImage)
                    if let index = items.firstIndex(of: placeholder) {
                        items.remove(at: index)
                        items.insert(newItem, at: index)
                    } else {
                        items.append(newItem)
                    }
                    sortSelected = .manual
                    await emitState()
                }
            } catch {
                onChange?(.failed(error))
            }
        }
    }
    
    func delete(uuid: UUID) {
        guard let index = items.firstIndex(where: { $0.uuid == uuid }) else { return }
        
        Task {
            do {
                try await self.service.delete(uuid: uuid)
                items.remove(at: index)
                await emitState()
            } catch {
                onChange?(.failed(error))
            }
        }
    }
    
    func checkIfSelected(sortOption: SortOption, isAscending: Bool) -> Bool {
        let checkOrder = sortOption == .manual ? true : isAscending == self.isAscending
        return sortSelected == sortOption && checkOrder
    }
    
    func setSortOption(_ sortOption: SortOption, isAscending: Bool) {
        sortSelected = sortOption
        self.isAscending = isAscending
        sortImages()
    }
    
    private func sortImages() {
        switch sortSelected {
        case .author:
            items.sort {
                let author1 = $0.author.capitalized
                let author2 = $1.author.capitalized
                // tiebreak
                if author1 != author2 {
                    return self.isAscending ? author1 < author2 : author1 > author2
                } else {
                    if $0.downloadedAt != $1.downloadedAt {
                        return self.isAscending ? $0.downloadedAt < $1.downloadedAt : $0.downloadedAt > $1.downloadedAt
                    } else {
                        return self.isAscending ? $0.uuid < $1.uuid : $0.uuid > $1.uuid
                    }
                }
            }
        case .downloadedAt:
            items.sort {
                if $0.downloadedAt != $1.downloadedAt {
                    return self.isAscending ? $0.downloadedAt < $1.downloadedAt : $0.downloadedAt > $1.downloadedAt
                } else {
                    let author1 = $0.author.capitalized
                    let author2 = $1.author.capitalized
                    if author1 != author2 {
                        return self.isAscending ? author1 < author2 : author1 > author2
                    } else {
                        return self.isAscending ? $0.uuid < $1.uuid : $0.uuid > $1.uuid
                    }
                }
            }
        case .manual:
            // keep the current order
            return
        }
        
        var imageOrdering: ImageOrdering = [:]
        for i in 0..<items.count {
            if items[i].order != i {
                imageOrdering[items[i].uuid] = Int32(i)
                items[i].order = i
            }
        }
        
        guard !imageOrdering.isEmpty else {
            // if there's no change, don't do anything
            return
        }

        Task {
            
            await emitState()
            
            do {
                try await service.update(imageOrdering: imageOrdering)
            } catch {
                // log error
            }
            
        }
    }
}
    
private extension MainViewModel {
    @MainActor
    func emitState() {
        onChange?(items.isEmpty ? .empty : .refresh(items))
    }
}
