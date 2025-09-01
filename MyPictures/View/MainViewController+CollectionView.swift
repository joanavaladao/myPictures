//
//  MainViewController+CollectionView.swift
//  MyPictures
//
//  Created by Joana Valadao on 2025-09-01.
//

import UIKit

extension MainViewController {
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
        
        dataSource?.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self = self,
                  kind == UICollectionView.elementKindSectionHeader else {
                return nil
            }
            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CollectionHeaderView.reuseIdentifier, for: indexPath) as! CollectionHeaderView
            headerView.contentMode = .scaleToFill
            headerView.backgroundColor = .systemBackground
            headerView.setLabel(value: String(localized: "\(viewModel.getItemsCount()) photos"))
            
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
}

// MARK: UICollectionViewDelegate
extension MainViewController: UICollectionViewDelegate {
    
    @MainActor
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        
        guard let item = dataSource?.itemIdentifier(for: indexPath) else {
            return nil
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let delete = UIAction(title: String(localized: "Delete"),
                                  image: UIImage(systemName: "trash"),
                                  attributes: .destructive) { _ in
                
                let alertVC = UIAlertController(title: String(localized: "Delete Selected Photos"),
                                                message: String(localized: "Are you sure you want to delete \(self?.viewModel.getNumberOfSelectedItems() ?? 0) photo? This operation can't be undone"),
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
        guard let selectedItem = dataSource?.itemIdentifier(for: indexPath) else {
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
              let selectedItem = dataSource?.itemIdentifier(for: indexPath)
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
        guard let flowLayout = layout as? UICollectionViewFlowLayout else {
            return .zero
        }
        
        let contentInsets = collectionView.adjustedContentInset
        let insets = flowLayout.sectionInset
        let spacing = flowLayout.minimumInteritemSpacing
        let availableWidth = collectionView.bounds.width - contentInsets.left - contentInsets.right - insets.left - insets.right
        
        // iPad: 220, iPhone: 160
        let minItemWidth: CGFloat = (traitCollection.horizontalSizeClass == .regular) ? 220 : 160
        
        var columns = max(1, Int((availableWidth + spacing) / (minItemWidth + spacing)))
        if traitCollection.horizontalSizeClass == .compact {
            columns = max(columns, 2)
        }
        
        let width = floor((availableWidth - CGFloat(columns - 1) * spacing) / CGFloat(columns))
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
