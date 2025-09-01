//
//  ImagePersistenceTests.swift
//  MyPicturesTests
//
//  Created by Joana Valadao on 2025-08-31.
//

@testable import MyPictures
import CoreData
import XCTest

final class ImagePersistenceTests: XCTestCase {
    private var sut: ImagePersistence!
    private var testContainer: NSPersistentContainer!
    private var tempDir: URL!
    private let dateRef = Date()

    override func setUpWithError() throws {
        testContainer = makeInMemoryContainer()
        tempDir = try makeTempBaseURL()
        sut = ImagePersistence(container: testContainer,
                               fileManager: .default,
                               baseURL: tempDir)
        
    }

    override func tearDownWithError() throws {
        sut = nil
        testContainer = nil
        try FileManager.default.removeItem(at: tempDir)
        tempDir = nil
    }

    // MARK: save
    func testSave() async throws {
        let data = Data([0x01, 0x02, 0x03])
        let image = try await sut.save(data,
                                       author: "Author 1",
                                       downloadDuration: 25.3,
                                       downloadedAt: dateRef,
                                       downloadURL: "https://test.ca/image1",
                                       imageURL: "https://test.ca/image1-page",
                                       cloudID: "001")

        XCTAssertEqual(image.filePath, "images/\(image.uuid)")
        XCTAssertEqual(image.author, "Author 1")
        XCTAssertEqual(image.order, 1)
        XCTAssertEqual(image.downloadDuration, 25.3)
        XCTAssertEqual(image.downloadedAt, dateRef)
        
        let image2 = try await sut.save(data,
                                        author: "Author 2",
                                        downloadDuration: 25.3,
                                        downloadedAt: dateRef,
                                        downloadURL: "https://test.ca/image1",
                                        imageURL: "https://test.ca/image1-page",
                                        cloudID: "002")

        XCTAssertEqual(image2.filePath, "images/\(image2.uuid)")
        XCTAssertEqual(image2.author, "Author 2")
        XCTAssertEqual(image2.order, 2)
        XCTAssertEqual(image2.downloadDuration, 25.3)
        XCTAssertEqual(image2.downloadedAt, dateRef)
    }
    
    // MARK: delete
    
    func testDelete_oneImage() async throws {
        let data = Data([0x01, 0x02, 0x03])
        let image1 = try await sut.save(data,
                                        author: "Author 1",
                                        downloadDuration: 25.3,
                                        downloadedAt: dateRef,
                                        downloadURL: "https://test.ca/image1",
                                        imageURL: "https://test.ca/image1-page",
                                        cloudID: "001")
        
        _ = try await sut.save(data,
                               author: "Author 2",
                               downloadDuration: 25.3,
                               downloadedAt: dateRef,
                               downloadURL: "https://test.ca/image1",
                               imageURL: "https://test.ca/image1-page",
                               cloudID: "002")
        
        var items = try await sut.fetchAll()
        XCTAssertEqual(items.count, 2)
        
        try await sut.delete(uuids: [image1.uuid])
        items = try await sut.fetchAll()
        XCTAssertEqual(items.count, 1)
        XCTAssertNotEqual(items[0].uuid, image1.uuid)
    }
    
    func testDelete_allImages() async throws {
        let data = Data([0x01, 0x02, 0x03])
        let image1 = try await sut.save(data,
                                        author: "Author 1",
                                        downloadDuration: 25.3,
                                        downloadedAt: dateRef,
                                        downloadURL: "https://test.ca/image1",
                                        imageURL: "https://test.ca/image1-page",
                                        cloudID: "001")
        
        let image2 = try await sut.save(data,
                                        author: "Author 2",
                                        downloadDuration: 25.3,
                                        downloadedAt: dateRef,
                                        downloadURL: "https://test.ca/image1",
                                        imageURL: "https://test.ca/image1-page",
                                        cloudID: "002")
        
        var items = try await sut.fetchAll()
        XCTAssertEqual(items.count, 2)
        
        try await sut.delete(uuids: [image1.uuid, image2.uuid])
        items = try await sut.fetchAll()
        XCTAssertEqual(items.count, 0)
    }
    
    // MARK: updateOrder
    
    func testUpdateOrder() async throws {
        let data = Data([0x01, 0x02, 0x03])
        let image1 = try await sut.save(data,
                                        author: "Author 1",
                                        downloadDuration: 25.3,
                                        downloadedAt: dateRef,
                                        downloadURL: "https://test.ca/image1",
                                        imageURL: "https://test.ca/image1-page",
                                        cloudID: "001")
        
        let image2 = try await sut.save(data,
                                        author: "Author 2",
                                        downloadDuration: 25.3,
                                        downloadedAt: dateRef,
                                        downloadURL: "https://test.ca/image1",
                                        imageURL: "https://test.ca/image1-page",
                                        cloudID: "002")
        
        var items = try await sut.fetchAll()
        XCTAssertEqual(items[0].uuid, image1.uuid)
        XCTAssertEqual(items[0].order, 1)
        XCTAssertEqual(items[1].uuid, image2.uuid)
        XCTAssertEqual(items[1].order, 2)
        
        try await sut.updateOrder([image1.uuid: 2, image2.uuid: 1])
        items = try await sut.fetchAll()
        XCTAssertEqual(items[0].uuid, image2.uuid)
        XCTAssertEqual(items[0].order, 1)
        XCTAssertEqual(items[1].uuid, image1.uuid)
        XCTAssertEqual(items[1].order, 2)
    }
}

// MARK: Helpers
private extension ImagePersistenceTests {
    func makeInMemoryContainer(modelName: String = "MyPictures") -> NSPersistentContainer {
        let container = NSPersistentContainer(name: modelName)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error { fatalError("Load in-memory failed: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }
    
    func makeTempBaseURL() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MyPicturesTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
