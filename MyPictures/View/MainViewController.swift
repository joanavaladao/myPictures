//
//  MainViewController.swift
//  MyPictures
//
//  Created by Joana Valadao on 2025-08-27.
//

import UIKit

class MainViewController: UIViewController {
    
    enum Section {
        case main
    }

    private let layout = UICollectionViewFlowLayout()
    private lazy var collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    private var dataSource: UICollectionViewDiffableDataSource<Section, MainViewModel.ImageInfo>! // TODO: change this
    private lazy var noImagesView: UIView = makeEmptyView()
    private var viewModel: MainViewModel
    
    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
    func setUpNavigationBar() {
        title = "My Photos"
        
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
        
        // Add Image Button
        let rightButton = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(addNewImage))
        navigationItem.rightBarButtonItem = rightButton
        
        // Sort Button
        let manual = UIAction(title: "Manual", state: viewModel.checkIfSelected(sortOption: .manual, isAscending: false) ? .on : .off) { [weak self] _ in
            self?.viewModel.setSortOption(.manual, isAscending: false)
        }
        
        let authorAsc = UIAction(title: "Author A-Z", state: viewModel.checkIfSelected(sortOption: .author, isAscending: true) ? .on : .off) { [weak self] _ in
            self?.viewModel.setSortOption(.author, isAscending: true)
        }
        
        let authorDesc = UIAction(title: "Author Z-A", state: viewModel.checkIfSelected(sortOption: .author, isAscending: false) ? .on : .off) { [weak self] _ in
            self?.viewModel.setSortOption(.author, isAscending: false)
        }
        
        let downloadedAtAsc = UIAction(title: "Date Added A-Z", state: viewModel.checkIfSelected(sortOption: .downloadedAt, isAscending: true) ? .on : .off) { [weak self] _ in
            self?.viewModel.setSortOption(.downloadedAt, isAscending: true)
        }
        
        let downloadedAtDesc = UIAction(title: "Date Added Z-A", state: viewModel.checkIfSelected(sortOption: .downloadedAt, isAscending: false) ? .on : .off) { [weak self] _ in
            self?.viewModel.setSortOption(.downloadedAt, isAscending: false)
        }

        let menu = UIMenu(title: "Sort by",
                          options: [.singleSelection],
                          children: [manual, authorAsc, authorDesc, downloadedAtAsc, downloadedAtDesc])

        let sortMenu = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: nil, action: nil)
        sortMenu.menu = menu
        navigationItem.leftBarButtonItem = sortMenu
    }
    
    @objc private func addNewImage() {
        viewModel.addNewImageWithSpinner()
    }
    
    func setUpCollectionView() {
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = .init(top: 8, left: 8, bottom: 8, right: 8)
        layout.estimatedItemSize = .zero
        
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
        
        configureDataSource()
    }
    
    func configureDataSource() {
        let register = UICollectionView.CellRegistration<ImageTextCell, MainViewModel.ImageInfo> { cell, _, item in
            cell.configure(image: item.image, text: item.author, isLoading: item.isLoading)
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, MainViewModel.ImageInfo>(collectionView: collectionView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: register, for: indexPath, item: item)
        }
    }
    
    func makeEmptyView() -> UIView {
        let emptyView = UIView()
        let imageView = UIImageView(image: UIImage(systemName: "photo.on.rectangle.fill"))
        imageView.tintColor = .systemGray
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "No images found"
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
    
    func setUpViewModel() {
        viewModel.loadImages()
        viewModel.onChange = { [weak self] state in
            switch state {
            case .refresh(let snapshot):
                self?.apply(items: snapshot)
            default:
                print("default")
            }
        }
    }
    
    func apply(items: [MainViewModel.ImageInfo], animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, MainViewModel.ImageInfo>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)

        dataSource.apply(snapshot, animatingDifferences: animated)
        collectionView.backgroundView?.isHidden = !items.isEmpty
    }
}

extension MainViewController: UICollectionViewDelegate {
    
    @MainActor
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let delete = UIAction(title: "Delete",
                                  image: UIImage(systemName: "trash"),
                                  attributes: .destructive) { _ in
                self?.viewModel.delete(uuid: item.uuid)
            }
            return UIMenu(children: [delete])
        }
    }
}

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
}
