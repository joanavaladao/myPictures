//
//  ModalViewController.swift
//  MyPictures
//
//  Created by Joana Valadao on 2025-08-30.
//

import UIKit

struct ModalContent {
    var modalTitle: String?
    var image: UIImage?
    var subtitle1: String?
    var subtitle2: String?
}

final class ModalViewController: UIViewController {
    private let titleLabel = UILabel()
    private let imageView = UIImageView()
    private let subtitle1Label = UILabel()
    private let subtitle2Label = UILabel()
    
    private var content: ModalContent
    
    init(content: ModalContent) {
        self.content = content
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buildModal()
    }
    
    func buildModal() {
        view.backgroundColor = .systemBackground
        
        // Title
        if let modalTitle = content.modalTitle {
            titleLabel.text = modalTitle
            titleLabel.isHidden = false
            titleLabel.font = .preferredFont(forTextStyle: .title1)
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 0
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
        } else {
            titleLabel.isHidden = true
        }
        
        if let image = content.image {
            imageView.image = image
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
        } else {
            imageView.isHidden = true
        }
        
        if let subtitle1 = content.subtitle1 {
            subtitle1Label.text = subtitle1
            subtitle1Label.isHidden = false
            subtitle1Label.font = .preferredFont(forTextStyle: .body)
            subtitle1Label.textAlignment = .center
            subtitle1Label.translatesAutoresizingMaskIntoConstraints = false
        }
        
        if let subtitle2 = content.subtitle2 {
            subtitle2Label.text = subtitle2
            subtitle2Label.isHidden = false
            subtitle2Label.font = .preferredFont(forTextStyle: .body)
            subtitle2Label.textAlignment = .center
            subtitle2Label.translatesAutoresizingMaskIntoConstraints = false
        }
        
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, imageView, subtitle1Label, subtitle2Label])
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.5)
        ])
    }
}
