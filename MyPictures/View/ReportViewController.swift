//
//  ReportViewController.swift
//  MyPictures
//
//  Created by Joana Valadao on 2025-09-01.
//

import UIKit

final class ReportViewController: UIViewController {

    private lazy var configuration: UICollectionLayoutListConfiguration = {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.headerMode = .supplementary
        return configuration
    }()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewCompositionalLayout.list(using: configuration))
    private var dataSource: UICollectionViewDiffableDataSource<ReportSection, ReportRow>?
    private var reportInformation: [ReportSection: [ReportRow]]
    
    init(reportInformation: [ReportSection: [ReportRow]]) {
        self.reportInformation = reportInformation
        super.init(nibName: nil, bundle: nil)
    }
                                    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        applySnapshot()
    }
    
    private func setupCollectionView() {
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Cell
        let cellRegister = UICollectionView.CellRegistration<UICollectionViewListCell, ReportRow> { cell, _, item in
            var content = UIListContentConfiguration.valueCell()
            content.text = item.title
            content.secondaryText = item.detail
            cell.contentConfiguration = content
        }
        
        dataSource = UICollectionViewDiffableDataSource<ReportSection, ReportRow>(collectionView: collectionView) {
            collectionView, indexPath, item  in
            collectionView.dequeueConfiguredReusableCell(using: cellRegister, for: indexPath, item: item)
        }
        
        // Header
        let headerRegister = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { header, _, indexPath in
            guard let section = ReportSection(rawValue: indexPath.section) else {
                return
            }
            var content = UIListContentConfiguration.header()
            content.text = section.title
            header.contentConfiguration = content
        }
        
        dataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader else { return nil }
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegister, for: indexPath)
        }
    }
        
    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<ReportSection, ReportRow>()
        snapshot.appendSections( [.summary, .authors] )
        if let summary = reportInformation[.summary] {
            snapshot.appendItems(summary, toSection: .summary)
        }
        
        if let authors = reportInformation[.authors] {
            snapshot.appendItems(authors, toSection: .authors)
        }

        dataSource?.apply(snapshot, animatingDifferences: true)
    }
}
