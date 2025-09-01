//
//  MainViewModelTests.swift
//  MyPicturesTests
//
//  Created by Joana Valadao on 2025-08-31.
//

import XCTest
@testable import MyPictures

final class MainViewModelTests: XCTestCase {
    private var service: MockImageService!
    private var sut: MainViewModel!
    private let pastDate = Date(timeIntervalSinceReferenceDate: -123456789.0)

    override func setUpWithError() throws {
        service = .init()
        sut = MainViewModel(service: service)
    }

    override func tearDownWithError() throws {
        service = nil
        sut = nil
    }

    // MARK: loadItems
    func testLoadItems_errorLoading_showError() async {
        service.shouldThrowError = true
        let expectation = expectation(description: "onChange failed")
        
        defer { sut.onChange = nil }
        sut.onChange = { [weak self] state in
            if case .failed(_) = state {
                XCTAssertTrue(self?.service.methodCalled["loadAllImages"] ?? false)
                expectation.fulfill()
            }
        }
        
        sut.loadItems()
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testLoadItems_itemsLoaded_showItems() async {
        let uuid1 = UUID()
        let uuid2 = UUID()
        service.responseLoadAllImages = [service.createImageItem(uuid: uuid1, order: 0),
                                         service.createImageItem(uuid: uuid2, order: 1)]
        
        let expectation = expectation(description: "onChange refresh")
        
        defer { sut.onChange = nil }
        sut.onChange = { [weak self] state in
            if case .refresh(let items) = state {
                let item1 = items[0]
                XCTAssertEqual(item1.uuid, uuid1)
                XCTAssertEqual(item1.author, "Author \(uuid1.uuidString)")
                XCTAssertEqual(item1.order, 0)
                XCTAssertEqual(item1.downloadedAt, self?.pastDate)
                XCTAssertEqual(item1.isLoading, false)
                XCTAssertTrue(self?.service.methodCalled["loadAllImages"] ?? false)

                expectation.fulfill()
            }
        }
        
        sut.loadItems()
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: addNewItemWithSpinner
    
    func testAddNewItemWithSpinner_errorAddingImage_showError() async {
        service.shouldThrowError = true
        
        let expectation1 = expectation(description: "onChange refresh with spinner")
        let expectation2 = expectation(description: "onChange failed")
        let expectation3 = expectation(description: "onChange refresh remove spinner")
        
        defer { sut.onChange = nil }
        sut.onChange = { [weak self] state in
            switch state {
            case .refresh(let items):
                if items.count == 1 {
                    XCTAssertTrue(items[0].isLoading)
                    expectation1.fulfill()
                }
            case .failed(let errorMessage):
                XCTAssertEqual(errorMessage, "Error adding new image. Please, try again")
                XCTAssertTrue(self?.service.methodCalled["addRandomImage"] ?? false)
                expectation2.fulfill()
            case .empty:
                expectation3.fulfill()
            }
        }
        
        sut.addNewItemWithSpinner()
        await fulfillment(of: [expectation1, expectation2, expectation3], timeout: 1.0)
    }
    
    func testAddNewItemWithSpinner_successAddingImage_showImage() async {
        service.responseAddRandomImage = service.createImageItem(uuid: UUID(), order: 0)
        
        let expectation1 = expectation(description: "onChange refresh with spinner")
        let expectation2 = expectation(description: "onChange refresh without spinner")
        
        defer { sut.onChange = nil }
        sut.onChange = { [weak self] state in
            if case .refresh(let items) = state,
               items.count == 1 {
                if items[0].isLoading {
                    expectation1.fulfill()
                } else {
                    XCTAssertTrue(self?.service.methodCalled["addRandomImage"] ?? false)
                    expectation2.fulfill()
                }
            }
        }
        
        sut.addNewItemWithSpinner()
        await fulfillment(of: [expectation1, expectation2], timeout: 1.0)
    }
    
    // MARK: deleteSelectedItems
    
    func testDeleteSelectedItems_errorDeleting_presentError() async {
        // Add items
        let uuid1 = UUID()
        let uuid2 = UUID()
        service.responseLoadAllImages = [
            service.createImageItem(uuid: uuid1, order: 0),
            service.createImageItem(uuid: uuid2, order: 1),
        ]
        
        let expectLoad = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh = state {
                expectLoad.fulfill()
            }
        }
        sut.loadItems()
        await fulfillment(of: [expectLoad], timeout: 1.0)
        sut.updateSelectionStatus(for: uuid1)
        
        // Test
        service.shouldThrowError = true
        let expectation = expectation(description: "onChange failed")
        
        defer { sut.onChange = nil }
        sut.onChange = { [weak self] state in
            if case .failed(_) = state {
                XCTAssertTrue(self?.service.methodCalled["delete"] ?? false)
                expectation.fulfill()
            }
        }
        
        sut.deleteSelectedItems()
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testDeleteSelectedItems_oneSelectedItem_deleteItem() async {
        // Add items
        let uuid1 = UUID()
        let uuid2 = UUID()
        service.responseLoadAllImages = [
            service.createImageItem(uuid: uuid1, order: 0),
            service.createImageItem(uuid: uuid2, order: 1),
        ]
        
        let expectLoad = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh = state {
                expectLoad.fulfill()
            }
        }
        sut.loadItems()
        await fulfillment(of: [expectLoad], timeout: 1.0)
        
        sut.updateSelectionStatus(for: uuid1)
        
        let expectationDelete = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { [weak self] state in
            if case .refresh(let items) = state {
                XCTAssertEqual(items.count, 1)
                XCTAssertEqual(items[0].uuid, uuid2)
                XCTAssertEqual(self?.sut.getNumberOfSelectedItems(), 0)
                XCTAssertTrue(self?.service.methodCalled["delete"] ?? false)
                expectationDelete.fulfill()
            }
        }
        sut.deleteSelectedItems()
        await fulfillment(of: [expectationDelete], timeout: 1.0)
    }
    
    func testDeleteSelectedItems_allItemsSelected_itemsArrayEmpty() async {
        // Add items
        let uuid1 = UUID()
        let uuid2 = UUID()
        service.responseLoadAllImages = [
            service.createImageItem(uuid: uuid1, order: 0),
            service.createImageItem(uuid: uuid2, order: 1),
        ]
        
        let expectLoad = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh = state {
                expectLoad.fulfill()
            }
        }
        sut.loadItems()
        await fulfillment(of: [expectLoad], timeout: 1.0)
        
        sut.selectAllItems()
        
        let expectationDelete = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { [weak self] state in
            if case .empty = state {
                XCTAssertTrue(self?.service.methodCalled["delete"] ?? false)
                expectationDelete.fulfill()
            }
        }
        sut.deleteSelectedItems()
        await fulfillment(of: [expectationDelete], timeout: 1.0)
    }
    
    // MARK: delete
    
    func testDelete_itemDoesntExist_nothingChanges() async {
        let uuid1 = UUID()
        service.responseLoadAllImages = [
            service.createImageItem(uuid: uuid1, order: 0),
        ]
        
        let expectationDelete = expectation(description: "onChange refresh")
        expectationDelete.isInverted = true
        defer { sut.onChange = nil }
        sut.onChange = { _ in
            expectationDelete.fulfill()
        }
        
        sut.delete(uuid: UUID())
        await fulfillment(of: [expectationDelete], timeout: 1.0)
        XCTAssertFalse(service.methodCalled["delete"] ?? false)
    }
    
    func testDelete_errorDeleting_showsErrorMessage() async {
        // Add items
        let uuid1 = UUID()
        let uuid2 = UUID()
        service.responseLoadAllImages = [
            service.createImageItem(uuid: uuid1, order: 0),
            service.createImageItem(uuid: uuid2, order: 1),
        ]
        
        let expectLoad = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh = state {
                expectLoad.fulfill()
            }
        }
        sut.loadItems()
        await fulfillment(of: [expectLoad], timeout: 1.0)
        
        service.shouldThrowError = true
        
        let expectationDelete = expectation(description: "onChange failed")
        defer { sut.onChange = nil }
        sut.onChange = { [weak self] state in
            if case .failed(_) = state {
                XCTAssertTrue(self?.service.methodCalled["delete"] ?? false)
                expectationDelete.fulfill()
            }
        }
        
        sut.delete(uuid: uuid1)
        await fulfillment(of: [expectationDelete], timeout: 1.0)
    }
    
    func testDelete_deleteItem_success() async {
        // Add items
        let uuid1 = UUID()
        let uuid2 = UUID()
        service.responseLoadAllImages = [
            service.createImageItem(uuid: uuid1, order: 0),
            service.createImageItem(uuid: uuid2, order: 1),
        ]
        
        let expectLoad = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh = state {
                expectLoad.fulfill()
            }
        }
        sut.loadItems()
        await fulfillment(of: [expectLoad], timeout: 1.0)
        
        let expectationDelete = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { [weak self] state in
            if case .refresh(let items) = state {
                XCTAssertEqual(items.count, 1)
                XCTAssertEqual(items[0].uuid, uuid2)
                XCTAssertTrue(self?.service.methodCalled["delete"] ?? false)
                expectationDelete.fulfill()
            }
        }
        
        sut.delete(uuid: uuid1)
        await fulfillment(of: [expectationDelete], timeout: 1.0)
    }
    
    // MARK: selectAllItems
    
    func testSelectAllItems() async {
        // Add items
        let uuid1 = UUID()
        let uuid2 = UUID()
        service.responseLoadAllImages = [
            service.createImageItem(uuid: uuid1, order: 0),
            service.createImageItem(uuid: uuid2, order: 1),
        ]
        
        let expectLoad = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh = state {
                expectLoad.fulfill()
            }
        }
        sut.loadItems()
        await fulfillment(of: [expectLoad], timeout: 1.0)
        
        sut.selectAllItems()
        
        XCTAssertEqual(sut.getNumberOfSelectedItems(), 2)
    }
    
    // MARK: updateSelectionStatus
    
    func testUpdateSelectAllStatus() async {
        // Add items
        let uuid = UUID()
        service.responseLoadAllImages = [
            service.createImageItem(uuid: uuid, order: 0)
        ]
        
        let expectLoad = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh = state {
                expectLoad.fulfill()
            }
        }
        sut.loadItems()
        await fulfillment(of: [expectLoad], timeout: 1.0)
        
        XCTAssertEqual(sut.getNumberOfSelectedItems(), 0)
        sut.updateSelectionStatus(for: uuid)
        XCTAssertEqual(sut.getNumberOfSelectedItems(), 1)
        sut.updateSelectionStatus(for: uuid)
        XCTAssertEqual(sut.getNumberOfSelectedItems(), 0)
    }
    
    // MARK: cancelSelection
    
    func testCancelSelection() async {
        // Add items
        let uuid1 = UUID()
        let uuid2 = UUID()
        service.responseLoadAllImages = [
            service.createImageItem(uuid: uuid1, order: 0),
            service.createImageItem(uuid: uuid2, order: 1),
        ]
        
        let expectLoad = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh = state {
                expectLoad.fulfill()
            }
        }
        sut.loadItems()
        await fulfillment(of: [expectLoad], timeout: 1.0)
        
        sut.selectAllItems()
        
        XCTAssertEqual(sut.getNumberOfSelectedItems(), 2)
        sut.cancelSelection()
        XCTAssertEqual(sut.getNumberOfSelectedItems(), 0)
    }
    
    
    // MARK: enableDeleteButton
    
    func testEnableDeleteButton_hasItensSelected_returnFalse() async {
        // Add items
        let uuid1 = UUID()
        let uuid2 = UUID()
        service.responseLoadAllImages = [
            service.createImageItem(uuid: uuid1, order: 0),
            service.createImageItem(uuid: uuid2, order: 1),
        ]
        
        let expectLoad = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh = state {
                expectLoad.fulfill()
            }
        }
        sut.loadItems()
        await fulfillment(of: [expectLoad], timeout: 1.0)
        
        sut.selectAllItems()
        
        XCTAssertTrue(sut.enableDeleteButton())
    }
    
    func testEnableDeleteButton_noItensSelected_returnTrue() async {
        // Add items
        let uuid1 = UUID()
        let uuid2 = UUID()
        service.responseLoadAllImages = [
            service.createImageItem(uuid: uuid1, order: 0),
            service.createImageItem(uuid: uuid2, order: 1),
        ]
        
        let expectLoad = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh = state {
                expectLoad.fulfill()
            }
        }
        sut.loadItems()
        await fulfillment(of: [expectLoad], timeout: 1.0)
        
        XCTAssertFalse(sut.enableDeleteButton())
    }
    
    // MARK: allItemsSelected
    
    func testAllItemsSelected_notAllItemsSelected_returnFalse() async {
        // Add items
        let uuid1 = UUID()
        let uuid2 = UUID()
        service.responseLoadAllImages = [
            service.createImageItem(uuid: uuid1, order: 0),
            service.createImageItem(uuid: uuid2, order: 1),
        ]
        
        let expectLoad = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh = state {
                expectLoad.fulfill()
            }
        }
        sut.loadItems()
        await fulfillment(of: [expectLoad], timeout: 1.0)
        sut.updateSelectionStatus(for: uuid1)
        
        XCTAssertFalse(sut.allItemsSelected())
    }

    func testAllItemsSelected_allItemsSelected_returnTrue() async {
        // Add items
        let uuid1 = UUID()
        let uuid2 = UUID()
        service.responseLoadAllImages = [
            service.createImageItem(uuid: uuid1, order: 0),
            service.createImageItem(uuid: uuid2, order: 1),
        ]
        
        let expectLoad = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh = state {
                expectLoad.fulfill()
            }
        }
        sut.loadItems()
        await fulfillment(of: [expectLoad], timeout: 1.0)
        sut.selectAllItems()
        
        XCTAssertTrue(sut.allItemsSelected())
    }
    
    // MARK: getNumberOfItems
    
    func testGetNumberOfItems_noItems_returnZero() async {
        XCTAssertEqual(sut.getNumberOfItems(), 0)
    }
    
    func testGetNumberOfItems_withItems_returnNumberOfItems() async {
        // Add items
        let uuid1 = UUID()
        let uuid2 = UUID()
        service.responseLoadAllImages = [
            service.createImageItem(uuid: uuid1, order: 0),
            service.createImageItem(uuid: uuid2, order: 1),
        ]
        
        let expectLoad = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh = state {
                expectLoad.fulfill()
            }
        }
        sut.loadItems()
        await fulfillment(of: [expectLoad], timeout: 1.0)
        
        XCTAssertEqual(sut.getNumberOfItems(), 2)
    }
    
    // MARK: getNumberOfSelectedItems
    
    func testGetNumberOfSelectedItems_noItemsSelected_returnZero() async {
        // Add items
        let uuid1 = UUID()
        let uuid2 = UUID()
        service.responseLoadAllImages = [
            service.createImageItem(uuid: uuid1, order: 0),
            service.createImageItem(uuid: uuid2, order: 1),
        ]
        
        let expectLoad = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh = state {
                expectLoad.fulfill()
            }
        }
        sut.loadItems()
        await fulfillment(of: [expectLoad], timeout: 1.0)
        
        XCTAssertEqual(sut.getNumberOfSelectedItems(), 0)
    }
    
    func testGetNumberOfSelectedItems_withItemsSelected_returnNumbeOfItems() async {
        // Add items
        let uuid1 = UUID()
        let uuid2 = UUID()
        service.responseLoadAllImages = [
            service.createImageItem(uuid: uuid1, order: 0),
            service.createImageItem(uuid: uuid2, order: 1),
        ]
        
        let expectLoad = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh = state {
                expectLoad.fulfill()
            }
        }
        sut.loadItems()
        await fulfillment(of: [expectLoad], timeout: 1.0)
        sut.updateSelectionStatus(for: uuid1)
        
        XCTAssertEqual(sut.getNumberOfSelectedItems(), 1)
    }
    
    // MARK: checkIfSelected
    
    func testCheckIfSelected_isTheSelectedSort_returnTrue() async {
        sut.setSortOption(.author, isAscending: true)
        XCTAssertTrue(sut.checkIfSelected(sortOption: .author, isAscending: true))
    }
    
    func testCheckIfSelected_isNotTheSelectedSort_returnFalse() async {
        sut.setSortOption(.author, isAscending: true)
        XCTAssertFalse(sut.checkIfSelected(sortOption: .author, isAscending: false))
        XCTAssertFalse(sut.checkIfSelected(sortOption: .downloadedAt, isAscending: true))
        XCTAssertFalse(sut.checkIfSelected(sortOption: .downloadedAt, isAscending: false))
    }
    
    // MARK: setSortOption
    
    func testSetSortOption_authorAZ() async {
        // Add items
        let uuid1 = UUID()
        let uuid2 = UUID()
        let uuid3 = UUID()
        let uuid4 = UUID()
        service.responseLoadAllImages = [
            ImageItem(uuid: uuid1, filePath: "images/img1", author: " Author A", order: 0, downloadedAt: Date(timeIntervalSinceReferenceDate: -123456789.0)),
            ImageItem(uuid: uuid2, filePath: "images/img2", author: " Author D", order: 0, downloadedAt: Date(timeIntervalSinceReferenceDate: -123456889.0)),
            ImageItem(uuid: uuid3, filePath: "images/img3", author: " Author C", order: 0, downloadedAt: Date(timeIntervalSinceReferenceDate: -123459889.0)),
            ImageItem(uuid: uuid4, filePath: "images/img4", author: " Author B", order: 0, downloadedAt: Date(timeIntervalSinceReferenceDate: -123459089.0)),
        ]
        
        let expectLoad = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh = state {
                expectLoad.fulfill()
            }
        }
        sut.loadItems()
        await fulfillment(of: [expectLoad], timeout: 1.0)
        
        let expectSort = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh(let items) = state {
                XCTAssertEqual(items.count, 4)
                
                XCTAssertEqual(items[0].uuid, uuid1)
                XCTAssertEqual(items[0].order, 0)
                
                XCTAssertEqual(items[1].uuid, uuid4)
                XCTAssertEqual(items[1].order, 1)
                
                XCTAssertEqual(items[2].uuid, uuid3)
                XCTAssertEqual(items[2].order, 2)
                
                XCTAssertEqual(items[3].uuid, uuid2)
                XCTAssertEqual(items[3].order, 3)
                
                expectSort.fulfill()
            }
        }
        sut.setSortOption(.author, isAscending: true)
        await fulfillment(of: [expectSort], timeout: 1.0)
    }
    
    func testSetSortOption_authorZA() async {
        // Add items
        let uuid1 = UUID()
        let uuid2 = UUID()
        let uuid3 = UUID()
        let uuid4 = UUID()
        service.responseLoadAllImages = [
            ImageItem(uuid: uuid1, filePath: "images/img1", author: " Author A", order: 0, downloadedAt: Date(timeIntervalSinceReferenceDate: -123456789.0)),
            ImageItem(uuid: uuid2, filePath: "images/img2", author: " Author D", order: 0, downloadedAt: Date(timeIntervalSinceReferenceDate: -123456889.0)),
            ImageItem(uuid: uuid3, filePath: "images/img3", author: " Author C", order: 0, downloadedAt: Date(timeIntervalSinceReferenceDate: -123459889.0)),
            ImageItem(uuid: uuid4, filePath: "images/img4", author: " Author B", order: 0, downloadedAt: Date(timeIntervalSinceReferenceDate: -123459089.0)),
        ]
        
        let expectLoad = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh = state {
                expectLoad.fulfill()
            }
        }
        sut.loadItems()
        await fulfillment(of: [expectLoad], timeout: 1.0)
        
        let expectSort = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh(let items) = state {
                XCTAssertEqual(items.count, 4)
                
                XCTAssertEqual(items[0].uuid, uuid2)
                XCTAssertEqual(items[0].order, 0)
                
                XCTAssertEqual(items[1].uuid, uuid3)
                XCTAssertEqual(items[1].order, 1)
                
                XCTAssertEqual(items[2].uuid, uuid4)
                XCTAssertEqual(items[2].order, 2)
                
                XCTAssertEqual(items[3].uuid, uuid1)
                XCTAssertEqual(items[3].order, 3)
                
                expectSort.fulfill()
            }
        }
        sut.setSortOption(.author, isAscending: false)
        await fulfillment(of: [expectSort], timeout: 1.0)
    }
    
    func testSetSortOption_dateAZ() async {
        // Add items
        let uuid1 = UUID()
        let uuid2 = UUID()
        let uuid3 = UUID()
        let uuid4 = UUID()
        service.responseLoadAllImages = [
            ImageItem(uuid: uuid1, filePath: "images/img1", author: " Author A", order: 0, downloadedAt: Date(timeIntervalSinceReferenceDate: -123456789.0)),
            ImageItem(uuid: uuid2, filePath: "images/img2", author: " Author D", order: 0, downloadedAt: Date(timeIntervalSinceReferenceDate: -123456889.0)),
            ImageItem(uuid: uuid3, filePath: "images/img3", author: " Author C", order: 0, downloadedAt: Date(timeIntervalSinceReferenceDate: -123459889.0)),
            ImageItem(uuid: uuid4, filePath: "images/img4", author: " Author B", order: 0, downloadedAt: Date(timeIntervalSinceReferenceDate: -123459089.0)),
        ]
        
        let expectLoad = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh = state {
                expectLoad.fulfill()
            }
        }
        sut.loadItems()
        await fulfillment(of: [expectLoad], timeout: 1.0)
        
        let expectSort = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh(let items) = state {
                XCTAssertEqual(items.count, 4)
                
                XCTAssertEqual(items[0].uuid, uuid3)
                XCTAssertEqual(items[0].order, 0)
                
                XCTAssertEqual(items[1].uuid, uuid4)
                XCTAssertEqual(items[1].order, 1)
                
                XCTAssertEqual(items[2].uuid, uuid2)
                XCTAssertEqual(items[2].order, 2)
                
                XCTAssertEqual(items[3].uuid, uuid1)
                XCTAssertEqual(items[3].order, 3)
                
                expectSort.fulfill()
            }
        }
        sut.setSortOption(.downloadedAt, isAscending: true)
        await fulfillment(of: [expectSort], timeout: 1.0)
    }
    
    func testSetSortOption_dateZA() async {
        // Add items
        let uuid1 = UUID()
        let uuid2 = UUID()
        let uuid3 = UUID()
        let uuid4 = UUID()
        service.responseLoadAllImages = [
            ImageItem(uuid: uuid1, filePath: "images/img1", author: " Author A", order: 0, downloadedAt: Date(timeIntervalSinceReferenceDate: -123456789.0)),
            ImageItem(uuid: uuid2, filePath: "images/img2", author: " Author D", order: 0, downloadedAt: Date(timeIntervalSinceReferenceDate: -123456889.0)),
            ImageItem(uuid: uuid3, filePath: "images/img3", author: " Author C", order: 0, downloadedAt: Date(timeIntervalSinceReferenceDate: -123459889.0)),
            ImageItem(uuid: uuid4, filePath: "images/img4", author: " Author B", order: 0, downloadedAt: Date(timeIntervalSinceReferenceDate: -123459089.0)),
        ]
        
        let expectLoad = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh = state {
                expectLoad.fulfill()
            }
        }
        sut.loadItems()
        await fulfillment(of: [expectLoad], timeout: 1.0)
        
        let expectSort = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh(let items) = state {
                XCTAssertEqual(items.count, 4)
                
                XCTAssertEqual(items[0].uuid, uuid1)
                XCTAssertEqual(items[0].order, 0)
                
                XCTAssertEqual(items[1].uuid, uuid2)
                XCTAssertEqual(items[1].order, 1)
                
                XCTAssertEqual(items[2].uuid, uuid4)
                XCTAssertEqual(items[2].order, 2)
                
                XCTAssertEqual(items[3].uuid, uuid3)
                XCTAssertEqual(items[3].order, 3)
                
                expectSort.fulfill()
            }
        }
        sut.setSortOption(.downloadedAt, isAscending: false)
        await fulfillment(of: [expectSort], timeout: 1.0)
    }
    
    // MARK: getItemsCount
    
    func testGetItemsCount_noItems_returnZero() {
        XCTAssertEqual(sut.getItemsCount(), 0)
    }
    
    func testGetItemsCount_withItems_returnNumberOfItems() async {
        // Add items
        let uuid1 = UUID()
        let uuid2 = UUID()
        service.responseLoadAllImages = [
            service.createImageItem(uuid: uuid1, order: 0),
            service.createImageItem(uuid: uuid2, order: 1),
        ]
        
        let expectLoad = expectation(description: "onChange refresh")
        defer { sut.onChange = nil }
        sut.onChange = { state in
            if case .refresh = state {
                expectLoad.fulfill()
            }
        }
        sut.loadItems()
        await fulfillment(of: [expectLoad], timeout: 1.0)
        XCTAssertEqual(sut.getItemsCount(), 2)
    }
}

private class MockImageService: ImageServiceProtocol {
    var shouldThrowError = false
    var responseAddRandomImage: ImageItem? = nil
    var responseLoadAllImages: [ImageItem] = []
    var methodCalled: [String: Bool] = [:]

    func addRandomImage() async throws -> ImageItem? {
        methodCalled["addRandomImage"] = true
        if shouldThrowError {
            throw NSError(domain: "MockImageService", code: 0, userInfo: nil)
        }
        return responseAddRandomImage
    }
    
    func loadAllImages() async throws -> [ImageItem] {
        methodCalled["loadAllImages"] = true
        if shouldThrowError {
            throw NSError(domain: "MockImageService", code: 0, userInfo: nil)
        }
        return responseLoadAllImages
    }
    
    func delete(uuids: [UUID]) async throws {
        methodCalled["delete"] = true
        if shouldThrowError {
            throw NSError(domain: "MockImageService", code: 0, userInfo: nil)
        }
    }
    
    func update(imageOrdering: MyPictures.ImageOrdering) async throws {
        methodCalled["update"] = true
        if shouldThrowError {
            throw NSError(domain: "MockImageService", code: 0, userInfo: nil)
        }
    }
    
    func createImageItem(uuid: UUID, order: Int = 0) -> ImageItem {
        ImageItem(uuid: uuid,
                  filePath: "images/\(uuid.uuidString)",
                  author: "Author \(uuid.uuidString)",
                  order: 0,
                  downloadDuration: 25.3,
                  downloadedAt: Date(timeIntervalSinceReferenceDate: -123456789.0))
    }
}
