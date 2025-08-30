//
//  ImageTextCell.swift
//  MyPictures
//
//  Created by Joana Valadao on 2025-08-29.
//

import UIKit

final class ImageTextCell: UICollectionViewCell {
    
    let imageView = UIImageView()
    let label = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // setup imageView
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        
        // setup label
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // spinner
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        
        contentView.addSubview(imageView)
        contentView.addSubview(label)
        imageView.addSubview(spinner)
        
        let multiplier = 0.8
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: multiplier),
            
            label.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            spinner.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        ])

        contentView.clipsToBounds = true
        backgroundColor = .systemBackground
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(image: UIImage?, text: String?, isLoading: Bool) {
        label.text = text ?? ""
        imageView.image = image
        isLoading ? spinner.startAnimating() : spinner.stopAnimating()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        spinner.stopAnimating()
        imageView.image = nil
        label.text = nil
    }
}
