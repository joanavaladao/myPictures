//
//  MainViewController+UINavigationBar.swift
//  MyPictures
//
//  Created by Joana Valadao on 2025-09-01.
//

import UIKit

extension MainViewController {
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
        let menu = createSortMenu()
        let sortMenu = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: nil, action: nil)
        sortMenu.menu = menu
        
        let reportButton = UIBarButtonItem(image: UIImage(systemName: "chart.bar.xaxis"), style: .plain, target: self, action: #selector(presentReport))
        
        navigationItem.leftBarButtonItems = [sortMenu, reportButton]
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
    
    @MainActor
    @objc func presentReport() {
        let reportInformation = viewModel.reportMetrics()
        let viewController = ReportViewController(reportInformation: reportInformation)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

private extension MainViewController {
    func createSortMenu() -> UIMenu {
        // Sort Button
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
                          children: [authorAsc, authorDesc, downloadedAtAsc, downloadedAtDesc])
        return menu
    }
}
