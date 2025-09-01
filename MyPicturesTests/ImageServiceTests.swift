//
//  ImageServiceTests.swift
//  MyPicturesTests
//
//  Created by Joana Valadao on 2025-08-31.
//

@testable import MyPictures
import XCTest

final class ImageServiceTests: XCTestCase {
    private var imageListAPI: MockImageListAPI!
    private var imageDownloader: MockImageDownloader!
    private var persistence: MockImagePersistence!
    private var mockURLSession: URLSession!
    
    private var sut: ImageService!
    
    override func setUpWithError() throws {
        imageListAPI = MockImageListAPI()
        imageDownloader = MockImageDownloader()
        persistence = MockImagePersistence()
        mockURLSession = MockURLProtocol.makeMockSession()
        sut = ImageService(imageListAPI: imageListAPI,
                           imageDownloader: imageDownloader,
                           persistence: persistence,
                           urlString: "https://test.com",
                           with: mockURLSession)
    }

    override func tearDownWithError() throws {
        imageListAPI = nil
        imageDownloader = nil
        persistence = nil
        mockURLSession = nil
        sut = nil
    }

    // MARK: addRandomImage
    func testAddRandomImage_errorFetchingList_throws() async throws {
        imageListAPI.shouldThrowError = true
        do {
            _ = try await sut.addRandomImage()
            XCTFail( "Expected error")
        } catch {
            // error expected
        }
    }
    
    func testAddRandomImage_noList_returnNil() async throws {
        imageListAPI.response = []
        do {
            let response = try await sut.addRandomImage()
            XCTAssertNil(response)
        } catch {
            XCTFail( "Expected to return nil")
        }
    }
    
    func testAddRandomImage_errorDownloadingData_throws() async throws {
        imageDownloader.shouldThrowError = true
        do {
            _ = try await sut.addRandomImage()
            XCTFail( "Expected error")
        } catch {
            // error expected
        }
    }
    
    func testAddRandomImage_noImageDownloaded_returnNil() async throws {
        imageDownloader.response = nil
        do {
            let response = try await sut.addRandomImage()
            XCTAssertNil(response)
        } catch {
            XCTFail( "Expected to return nil")
        }
    }
    
    func testAddRandomImage_errorSavingImage_throws() async throws {
        persistence.shouldThrowError = true
        do {
            _ = try await sut.addRandomImage()
            XCTFail( "Expected error")
        } catch {
            // error expected
        }
    }
    
    func testAddRandomImage_successfullySaved_returnImageItem() async throws {
        let uuid = UUID()
        persistence.responseSave = persistence.createImageItem(uuid: uuid)
        do {
            let response = try await sut.addRandomImage()
            let image = try XCTUnwrap(response)
            XCTAssertEqual(image.uuid, uuid)
            XCTAssertEqual(image.filePath, "images/\(uuid.uuidString)")
            XCTAssertEqual(image.author, "Author \(uuid.uuidString)")
            XCTAssertEqual(image.order, 0)
            XCTAssertEqual(image.downloadDuration, 25.3)
            XCTAssertEqual(image.downloadedAt, Date(timeIntervalSinceReferenceDate: -123456789.0))
        } catch {
            XCTFail("Expected do succeed")
        }
    }
    
    // MARK: loadAllImages
    
    func testLoadAllImages_errorFetchAll_throws() async throws {
        persistence.shouldThrowError = true
        do {
            _ = try await sut.loadAllImages()
            XCTFail( "Expected error")
        } catch {
            // error expected
        }
    }
    
    func testLoadAllImages_getEmptyList_returnEmptyArray() async throws {
        persistence.responseFetchAll = []
        
        do {
            let response = try await sut.loadAllImages()
            XCTAssertEqual(response.count, 0)
        } catch {
            XCTFail("Expected do succeed")
        }
    }
    
    func testLoadAllImages_getArrayOfImages_returnArrayOfImages() async throws {
        let uuid1 = UUID()
        let uuid2 = UUID()
        persistence.responseFetchAll = [
            persistence.createImageItem(uuid: uuid1),
            persistence.createImageItem(uuid: uuid2, order: 1)
        ]
        
        do {
            let response = try await sut.loadAllImages()
            XCTAssertEqual(response.count, 2)
            let item1 = try XCTUnwrap(response.filter { $0.uuid == uuid1 }.first)
            XCTAssertEqual(item1.uuid, uuid1)
            XCTAssertEqual(item1.filePath, "images/\(uuid1.uuidString)")
            XCTAssertEqual(item1.author, "Author \(uuid1.uuidString)")
            XCTAssertEqual(item1.order, 0)
            XCTAssertEqual(item1.downloadDuration, 25.3)
            XCTAssertEqual(item1.downloadedAt, Date(timeIntervalSinceReferenceDate: -123456789.0))
            
            let item2 = try XCTUnwrap(response.filter { $0.uuid == uuid2 }.first)
            XCTAssertEqual(item2.uuid, uuid2)
            XCTAssertEqual(item2.filePath, "images/\(uuid2.uuidString)")
            XCTAssertEqual(item2.author, "Author \(uuid2.uuidString)")
            XCTAssertEqual(item2.order, 0)
            XCTAssertEqual(item2.downloadDuration, 25.3)
            XCTAssertEqual(item2.downloadedAt, Date(timeIntervalSinceReferenceDate: -123456789.0))
        } catch {
            XCTFail("Expected do succeed")
        }
    }
    
    // MARK: delete
    
    func testDelete_errorDelete_throws() async throws {
        persistence.shouldThrowError = true
        do {
            try await sut.delete(uuids: [UUID()])
            XCTFail( "Expected error")
        } catch {
            // expected to fail
        }
    }
    
    func testDelete_successDelete_noThrow() async throws {
        do {
            try await sut.delete(uuids: [UUID()])
        } catch {
            XCTFail("Expected do succeed")
        }
    }
    
    // MARK: update
    
    func testUpdate_errorUpdate_throws() async throws {
        persistence.shouldThrowError = true
        do {
            try await sut.update(imageOrdering: [UUID(): 1, UUID(): 4])
            XCTFail( "Expected error")
        } catch {
            // expected to fail
        }
    }
    
    func testUpdate_successUpdate_noThrow() async throws {
        do {
            try await sut.update(imageOrdering: [UUID(): 1, UUID(): 4])
        } catch {
            XCTFail("Expected do succeed")
        }
    }
}


private class MockImageListAPI: ImageListAPIProtocol {
    var shouldThrowError = false
    var response: [PicsumInfo] = [.init(id: "01", author: "Author1", width: 100, height: 100, url: "https://test.com/img1", download_url: "https://test.com/download-img1")]
    
    func fetchList(page: Int, limit: Int, urlString: String, urlSession: URLSession) async throws -> [PicsumInfo] {
        if shouldThrowError {
            throw NSError(domain: "MockImageListAPI", code: 0, userInfo: nil)
        }
        return response
    }
}

private class MockImageDownloader: ImageDownloaderProtocol {
    var shouldThrowError = false
    var response: ImageDownloaded? = ImageDownloaded(data: Data([0x01, 0x02, 0x03]),
                                                     duration: 25.3,
                                                     downloadedAt: Date(timeIntervalSinceReferenceDate: -123456789.0))
    
    func download(from imageURL: String, urlSession: URLSession) async throws -> ImageDownloaded? {
        if shouldThrowError {
            throw NSError(domain: "MockImageDownloader", code: 1, userInfo: nil)
        }
        return response
    }
}

private class MockImagePersistence: ImagePersistenceProtocol {
    var shouldThrowError = false
    var responseSave: ImageItem? = nil
    var responseFetchAll: [ImageItem] = []
    
    func save(_ imageData: Data, author: String, downloadDuration: TimeInterval, downloadedAt: Date, downloadURL: String, imageURL: String, cloudID: String?) async throws -> ImageItem {
        if shouldThrowError {
            throw NSError(domain: "MockImagePersistence", code: 1, userInfo: nil)
        } else if let response = responseSave {
            return response
        }
        return ImageItem(uuid: UUID(), filePath: "test")
    }
    
    func delete(uuids: [UUID]) async throws {
        if shouldThrowError {
            throw NSError(domain: "MockImagePersistence", code: 1, userInfo: nil)
        }
    }
    
    func fetchAll() async throws -> [ImageItem] {
        if shouldThrowError {
            throw NSError(domain: "MockImagePersistence", code: 1, userInfo: nil)
        }
        return responseFetchAll
    }
    
    func updateOrder(_ ordering: MyPictures.ImageOrdering) async throws {
        if shouldThrowError {
            throw NSError(domain: "MockImagePersistence", code: 1, userInfo: nil)
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


