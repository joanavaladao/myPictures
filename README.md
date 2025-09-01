# My Photos
An iOS app that fetches random images from the Picsum
 API, persists them locally, and allows the user to manage their collection.

## Features
* Fetch and save a random image from the API.
* Display images with author names in a responsive grid (iPhone/iPad).
* Multi-selection with batch delete.
* Long-press with the option to delete one image.
* Sort by Author or Date Added (A-Z / Z-A).
* Report view with metrics (total, downloaded today, unique authors).
* Modal sheet with image details.

## Architecture
* MVVM
* Swift concurrency (async/await)
* UICollectionViewDiffableDataSource for list management

## Testing
* Unit tests for Service, Persistence, and ViewModel.
* Network mocking with URLProtocol.
* Core Data in-memory store for persistence tests.

## How to Run
* Clone the repository.
* Open MyPictures.xcodeproj in Xcode.
* Run on Simulator or device.
