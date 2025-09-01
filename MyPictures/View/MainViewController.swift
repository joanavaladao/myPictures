//
//  MainViewController.swift
//  MyPictures
//
//  Created by Joana Valadao on 2025-08-27.
//

import UIKit

class MainViewController: UIViewController {
    
    // MARK: enum Section
    enum Section {
        case main
    }

    // MARK: UI components
    let layout = UICollectionViewFlowLayout()
    lazy var collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    var dataSource: UICollectionViewDiffableDataSource<Section, MainViewModel.ImageInfo>?
    lazy var noImagesView: UIView = makeEmptyView()
    var viewModel: MainViewModel
    
    // Toolbar buttons
    lazy var addPhotoButton = UIBarButtonItem(title: String(localized: "Add"), style: .plain, target: self, action: #selector(addNewImage))
    lazy var selectButton = UIBarButtonItem(title: String(localized: "Select"), style: .plain, target: self, action: #selector(enterSelectionMode))
    lazy var cancelButton  = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSelectionMode))
    lazy var deleteButton  = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteSelectedPhotos))
    lazy var selectAllButton = UIBarButtonItem(title: String(localized: "Select All"), style: .plain, target: self, action: #selector(selectAllPhotos))
    lazy var deselectAllButton = UIBarButtonItem(title: String(localized: "Deselect All"), style: .plain, target: self, action: #selector(deselectAllPhotos))
    

    // MARK: Initializers
    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpNavigationBar()
        setUpCollectionView()
        setUpViewModel()

        view.backgroundColor = .systemBackground
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
}

private extension MainViewController {
    // MARK: Setup View Model
    func setUpViewModel() {
        viewModel.loadItems()
        viewModel.onChange = { [weak self] state in
            switch state {
            case .refresh(let snapshot):
                self?.apply(items: snapshot)
                self?.setUpNavigationBarLeftMenu()
            case .empty:
                self?.apply(items: [])
            case .failed(let message):
                let alertVC = UIAlertController(title: String(localized: "Error"),
                                                message: message,
                                                preferredStyle: .alert)
                alertVC.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel))
                self?.present(alertVC, animated: true)
            }
        }
    }
    
    // MARK: Actions
    func apply(items: [MainViewModel.ImageInfo], animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, MainViewModel.ImageInfo>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)

        dataSource?.apply(snapshot, animatingDifferences: animated) { [ weak self] in
            if let photosCount = self?.viewModel.getItemsCount(),
               let header = self?.collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? CollectionHeaderView {
                header.setLabel(value: String(localized: "\(photosCount) photos"))
            }
        }
        collectionView.backgroundView?.isHidden = !items.isEmpty
    }

    
    @objc private func addNewImage() {
        viewModel.addNewItemWithSpinner()
    }
    
    @MainActor
    @objc private func enterSelectionMode() {
        navigationItem.rightBarButtonItems = [addPhotoButton, cancelButton]
        viewModel.isInSelectionMode = true
        setUpBottomBar()
    }
    
    @MainActor
    @objc private func cancelSelectionMode() {
        navigationItem.rightBarButtonItems = [addPhotoButton, selectButton]
        viewModel.isInSelectionMode = false
        viewModel.cancelSelection()
        deselectAllPhotos()
        setUpBottomBar()
    }

    @objc @MainActor
    private func deselectAllPhotos() {
        for indexPath in collectionView.indexPathsForSelectedItems ?? [] {
            collectionView.deselectItem(at: indexPath, animated: false)
        }
        viewModel.cancelSelection()
        setUpBottomBar()
    }
    
    @objc func deleteSelectedPhotos() {
        let alertVC = UIAlertController(title: String(localized: "Delete Selected Photos"),
                                        message: String(localized: "Are you sure you want to delete \(viewModel.getNumberOfSelectedItems()) photo? This operation can't be undone"),
                                        preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel))
        alertVC.addAction(UIAlertAction(title: String(localized: "Delete"), style: .destructive) { [weak self] (action) in
            self?.viewModel.deleteSelectedItems()
        })
        present(alertVC, animated: true)
    }

    @MainActor
    @objc func selectAllPhotos() {
        for i in 0..<viewModel.getNumberOfItems() {
            collectionView.selectItem(at: IndexPath(item: i, section: 0), animated: true, scrollPosition: [])
        }

        viewModel.selectAllItems()
        setUpBottomBar()
    }
}
