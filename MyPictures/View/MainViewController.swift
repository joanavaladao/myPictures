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
    private let layout = UICollectionViewFlowLayout()
    private lazy var collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    private var dataSource: UICollectionViewDiffableDataSource<Section, MainViewModel.ImageInfo>! // TODO: change this
    private lazy var noImagesView: UIView = makeEmptyView()
    private var viewModel: MainViewModel
    
    // Toolbar buttons
    private lazy var addPhotoButton = UIBarButtonItem(title: String(localized: "Add"), style: .plain, target: self, action: #selector(addNewImage))
    private lazy var selectButton = UIBarButtonItem(title: String(localized: "Select"), style: .plain, target: self, action: #selector(enterSelectionMode))
    private lazy var cancelButton  = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSelectionMode))
    private lazy var deleteButton  = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteSelectedPhotos))
    private lazy var selectAllButton = UIBarButtonItem(title: String(localized: "Select All"), style: .plain, target: self, action: #selector(selectAllPhotos))
    private lazy var deselectAllButton = UIBarButtonItem(title: String(localized: "Deselect All"), style: .plain, target: self, action: #selector(deselectAllPhotos))
    

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
    // MARK: Setup Navigation Bar
    func setUpNavigationBar() {
        title = String(localized: "My Photos")
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        let navigationBar = navigationController?.navigationBar
        navigationBar?.standardAppearance = appearance
        navigationBar?.scrollEdgeAppearance = appearance
        
        if #available(iOS 15.0, *) {
            navigationBar?.scrollEdgeAppearance = appearance
        }
        
        navigationBar?.tintColor = .white
        navigationBar?.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        navigationBar?.barStyle = .black
        navigationBar?.isTranslucent = false
        
        setUpNavigationBarRightMenu()
        setUpNavigationBarLeftMenu()
        setUpBottomBar()
    }
    
    func setUpNavigationBarRightMenu() {
        // Add Image Button
        navigationItem.rightBarButtonItems = [addPhotoButton, selectButton]
    }
    
    func setUpNavigationBarLeftMenu() {
        // Sort Button
        let manual = UIAction(title: String(localized: "Manual"), state: viewModel.checkIfSelected(sortOption: .manual, isAscending: false) ? .on : .off) { [weak self] _ in
            self?.viewModel.setSortOption(.manual, isAscending: false)
        }
        
        let authorAsc = UIAction(title: String(localized: "Author A-Z"), state: viewModel.checkIfSelected(sortOption: .author, isAscending: true) ? .on : .off) { [weak self] _ in
            self?.viewModel.setSortOption(.author, isAscending: true)
        }
        
        let authorDesc = UIAction(title: String(localized: "Author Z-A"), state: viewModel.checkIfSelected(sortOption: .author, isAscending: false) ? .on : .off) { [weak self] _ in
            self?.viewModel.setSortOption(.author, isAscending: false)
        }
        
        let downloadedAtAsc = UIAction(title: String(localized: "Date Added A-Z"), state: viewModel.checkIfSelected(sortOption: .downloadedAt, isAscending: true) ? .on : .off) { [weak self] _ in
            self?.viewModel.setSortOption(.downloadedAt, isAscending: true)
        }
        
        let downloadedAtDesc = UIAction(title: String(localized: "Date Added Z-A"), state: viewModel.checkIfSelected(sortOption: .downloadedAt, isAscending: false) ? .on : .off) { [weak self] _ in
            self?.viewModel.setSortOption(.downloadedAt, isAscending: false)
        }

        let menu = UIMenu(title: String(localized: "Sort by"),
                          options: [.singleSelection],
                          children: [manual, authorAsc, authorDesc, downloadedAtAsc, downloadedAtDesc])

        let sortMenu = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: nil, action: nil)
        sortMenu.menu = menu
        navigationItem.leftBarButtonItem = sortMenu
    }
    
    @MainActor
    func setUpBottomBar() {
        deleteButton.isEnabled = viewModel.enableDeleteButton()
        if viewModel.allItemsSelected() {
            setToolbarItems([.flexibleSpace(), deselectAllButton, .flexibleSpace(), deleteButton, .flexibleSpace()], animated: true)
        } else {
            setToolbarItems([.flexibleSpace(), selectAllButton, .flexibleSpace(), deleteButton, .flexibleSpace()], animated: true)
        }
        
        navigationController?.setToolbarHidden(!viewModel.isInSelectionMode, animated: true)
    }
    
    // MARK: Setup Collection View
    
    func setUpCollectionView() {
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = .init(top: 8, left: 8, bottom: 8, right: 8)
        layout.estimatedItemSize = .zero
        layout.sectionHeadersPinToVisibleBounds = true
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        ])
        
        collectionView.backgroundView = noImagesView
        collectionView.backgroundView?.isHidden = false
        collectionView.alwaysBounceVertical = true
        collectionView.allowsMultipleSelection = true
        
        configureDataSource()
        configureSubtitle()
    }
    
    func configureDataSource() {
        let register = UICollectionView.CellRegistration<ImageTextCell, MainViewModel.ImageInfo> { [weak self] cell, _, item in
            cell.configure(image: item.image, text: item.author, isLoading: item.isLoading, isSelectionMode: self?.viewModel.isInSelectionMode ?? false)
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, MainViewModel.ImageInfo>(collectionView: collectionView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: register, for: indexPath, item: item)
        }
    }
    
    func configureSubtitle() {
        collectionView.register(CollectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: CollectionHeaderView.reuseIdentifier)
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self = self,
                  kind == UICollectionView.elementKindSectionHeader else {
                return nil
            }
            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CollectionHeaderView.reuseIdentifier, for: indexPath) as! CollectionHeaderView
            headerView.contentMode = .scaleToFill
            headerView.backgroundColor = .systemBackground
            headerView.setLabel(value: String(localized: "\(viewModel.getImageCount()) photos"))
            
            return headerView
        }
    }
    
    func makeEmptyView() -> UIView {
        let emptyView = UIView()
        let imageView = UIImageView(image: UIImage(systemName: "photo.on.rectangle.fill"))
        imageView.tintColor = .systemGray
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = String(localized: "No images found")
        label.font = .preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        
        let stack = UIStackView(arrangedSubviews: [imageView, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        emptyView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor),
            stack.widthAnchor.constraint(lessThanOrEqualTo: emptyView.widthAnchor, multiplier: 0.8),
            imageView.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: 0.7),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        ])
        return emptyView
    }
    
    // MARK: Setup View Model
    func setUpViewModel() {
        viewModel.loadImages()
        viewModel.onChange = { [weak self] state in
            switch state {
            case .refresh(let snapshot):
                self?.apply(items: snapshot)
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

        dataSource.apply(snapshot, animatingDifferences: animated) { [ weak self] in
            if let photosCount = self?.viewModel.getImageCount(),
               let header = self?.collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? CollectionHeaderView {
                header.setLabel(value: String(localized: "\(photosCount) photos"))
            }
        }
        collectionView.backgroundView?.isHidden = !items.isEmpty
    }

    
    @objc private func addNewImage() {
        viewModel.addNewImageWithSpinner()
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
                                        message: String(localized: "Are you sure you want to delete \(viewModel.getNumberOfSelectedImages()) photos? This operation can't be undone"),
                                        preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel))
        alertVC.addAction(UIAlertAction(title: String(localized: "Delete"), style: .destructive) { [weak self] (action) in
            self?.viewModel.deleteSelectedItems()
        })
        present(alertVC, animated: true)
    }

    @MainActor
    @objc func selectAllPhotos() {
        for i in 0..<viewModel.getNumberOfImages() {
            collectionView.selectItem(at: IndexPath(item: i, section: 0), animated: true, scrollPosition: [])
        }

        viewModel.selectAllItems()
        setUpBottomBar()
    }
}

// MARK: UICollectionViewDelegate
extension MainViewController: UICollectionViewDelegate {
    
    @MainActor
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let delete = UIAction(title: String(localized: "Delete"),
                                  image: UIImage(systemName: "trash"),
                                  attributes: .destructive) { _ in
                
                let alertVC = UIAlertController(title: String(localized: "Delete Selected Photos"),
                                                message: String(localized: "Are you sure you want to delete \(self?.viewModel.getNumberOfSelectedImages() ?? 0) photo? This operation can't be undone"),
                                                preferredStyle: .alert)
                alertVC.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel))
                alertVC.addAction(UIAlertAction(title: String(localized: "Delete"), style: .destructive) { [weak self] (action) in
                    self?.viewModel.delete(uuid: item.uuid)
                })
                self?.present(alertVC, animated: true)
                
                
            }
            return UIMenu(children: [delete])
        }
    }
    
    @MainActor
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedItem = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        if viewModel.isInSelectionMode {
            viewModel.updateSelectionStatus(for: selectedItem.uuid)
            setUpBottomBar()
        } else {
            let modal = ModalViewController(content: ModalContent(image: selectedItem.image, subtitle1: selectedItem.author, subtitle2: String(localized: "Downloaded at: \(selectedItem.dateString())")))
            if let sheet = modal.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.prefersEdgeAttachedInCompactHeight = true
                sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
            }
            present(modal, animated: true)
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }
    
    @MainActor
    func collectionView(_ cv: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard viewModel.isInSelectionMode,
              let selectedItem = dataSource.itemIdentifier(for: indexPath)
        else {
            return
        }

        viewModel.updateSelectionStatus(for: selectedItem.uuid)
        setUpBottomBar()
    }
}

// MARK: UICollectionViewDelegateFlowLayout
extension MainViewController: UICollectionViewDelegateFlowLayout {
    @MainActor
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns: CGFloat = 2
        let spacing = self.layout.minimumInteritemSpacing
        let insets = self.layout.sectionInset
        let total = insets.left + insets.right + spacing * (columns - 1)
        let width = floor((collectionView.bounds.width - total)/columns)
        
        let imageHeight = width * 0.8
        let font = UIFont.preferredFont(forTextStyle: .footnote)
        let labelHeight: CGFloat = ceil(font.lineHeight)
        
        return CGSize(width: width, height: imageHeight + labelHeight + 8)
    }
    
    @MainActor
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        .init(width: collectionView.bounds.width, height: 28)
    }
}
