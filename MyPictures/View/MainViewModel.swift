//
//  MainViewModel.swift
//  MyPictures
//
//  Created by Joana Valadao on 2025-08-29.
//

import UIKit

final class MainViewModel {
    private let service: ImageServiceProtocol
    private var items: [ImageInfo] = []
    private var selectedItems: [UUID] = []
    private var sortSelected: SortOption = .manual
    private var isAscending: Bool = true
    var isInSelectionMode = false
    var onChange: ((DataState) -> Void)?
    
    init(service: ImageServiceProtocol = ImageService()) {
        self.service = service
    }
    
    // MARK: Image Manipulation
    func loadItems() {
        Task {
            do {
                let savedItems = try await self.service.loadAllImages()
                items = savedItems.map { .init(from: $0) }
                await emitState()
            } catch {
                logError(error: error)
                await presentError(String(localized: "Error loading images. Please, try again"))
            }
        }
    }

    func addNewItemWithSpinner() {
        
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
                logError(error: error)
                await presentError(String(localized: "Error adding new image. Please, try again"))
                if let index = items.firstIndex(of: placeholder) {
                    items.remove(at: index)
                    await emitState()
                }
            }
        }
    }
    
    func deleteSelectedItems() {
        let uuids = selectedItems
        guard uuids.count > 0 else {
            return
        }

        Task {
            do {
                try await self.service.delete(uuids: selectedItems)
                
                items.removeAll { uuids.contains($0.uuid) }
                selectedItems.removeAll()
                
                await emitState()
            } catch {
                logError(error: error)
                await presentError(String(localized: "Error deleting the image. Please, try again"))
            }
        }
    }
    
    func delete(uuid: UUID) {
        guard let index = items.firstIndex(where: { $0.uuid == uuid }) else { return }
        
        Task {
            do {
                try await self.service.delete(uuids: [uuid])
                items.remove(at: index)
                await emitState()
            } catch {
                logError(error: error)
                await presentError(String(localized: "Error deleting the image. Please, try again"))
            }
        }
    }
    
    // MARK: Screen Control

    func selectAllItems() {
        selectedItems = items.map { $0.uuid }
    }
    
    func updateSelectionStatus(for uuid: UUID) {
        if let index = selectedItems.firstIndex(of: uuid) {
            selectedItems.remove(at: index)
        } else {
            selectedItems.append(uuid)
        }
    }
    
    func cancelSelection() {
        selectedItems.removeAll()
    }
    
    func enableDeleteButton() -> Bool {
        !selectedItems.isEmpty
    }
    
    func allItemsSelected() -> Bool {
        selectedItems.count == items.count
    }
    
    func getNumberOfItems() -> Int {
        items.count
    }
    
    func getNumberOfSelectedItems() -> Int {
        selectedItems.count
    }
    
    func checkIfSelected(sortOption: SortOption, isAscending: Bool) -> Bool {
        let checkOrder = sortOption == .manual ? true : isAscending == self.isAscending
        return sortSelected == sortOption && checkOrder
    }
    
    func setSortOption(_ sortOption: SortOption, isAscending: Bool) {
        sortSelected = sortOption
        self.isAscending = isAscending
        sortItems()
    }
    
    func getItemsCount() -> Int {
        items.count
    }
}
    
// MARK: Helper Functions
private extension MainViewModel {
    func sortItems() {
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
        
        var itemsToBeUpdated: ImageOrdering = [:]
        for i in 0..<items.count {
            if items[i].order != i {
                itemsToBeUpdated[items[i].uuid] = Int32(i)
                items[i].order = i
            }
        }
        
        guard !itemsToBeUpdated.isEmpty else {
            // if there's no change, don't do anything
            return
        }

        Task {
            await emitState()
            do {
                try await service.update(imageOrdering: itemsToBeUpdated)
            } catch {
                logError(error: error)
            }
        }
    }
    
    @MainActor
    func emitState() {
        onChange?(items.isEmpty ? .empty : .refresh(items))
    }
    
    @MainActor
    func presentError(_ message: String) {
        onChange?(.failed(message))
    }
    
    func logError(error: Error) {
        print("Error: \(error)")
    }
}

// MARK: Reports
extension MainViewModel {
    func reportMetrics(calendar: Calendar = .current) -> [ReportSection: [ReportRow]] {
        let reportItems = items.filter { !$0.isLoading }
        let total = reportItems.count
        let imagesToday = reportItems.filter { calendar.isDateInToday($0.downloadedAt) }.count
        let imagesByAuthorsDict = Dictionary(grouping: reportItems, by: \.author).mapValues(\.count)
        let imagesByAuthors = imagesByAuthorsDict
            .sorted { (a, b) in a.value == b.value ? a.key < b.key : a.value > b.value }
            .map { ($0.key, $0.value) }
        let uniqueAuthors = imagesByAuthors.count
        
        var reportInformation: [ReportSection: [ReportRow]] = [:]
        reportInformation[.summary] = [.init(title: String(localized: "Number of photos"), detail: String(total)),
                                       .init(title: String(localized: "Photos downloaded today"), detail: String(imagesToday)),
                                       .init(title: String(localized: "Unique authors"), detail: String(uniqueAuthors))]
        
        if imagesByAuthors.isEmpty {
            reportInformation[.authors] = [.init(title: String(localized: "No authors"), detail: "")]
        } else {
            reportInformation[.authors] = imagesByAuthors.map { .init(title: $0.0, detail: String($0.1)) }
        }
        
        return reportInformation
    }
}
