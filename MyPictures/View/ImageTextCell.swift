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
    private let checkmarkImageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
    
    override var isSelected: Bool {
        didSet {
            updateCheckMark(animated: true)
        }
    }
    
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
        
        // checkmark
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        checkmarkImageView.backgroundColor = .white
        checkmarkImageView.layer.cornerRadius = 12
        
        contentView.addSubview(imageView)
        contentView.addSubview(label)
        imageView.addSubview(spinner)
        imageView.addSubview(checkmarkImageView)
        
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
            spinner.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            
            checkmarkImageView.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 4),
            checkmarkImageView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -4),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 24),
        ])

        contentView.clipsToBounds = true
        backgroundColor = .systemBackground
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(image: UIImage?, text: String?, isLoading: Bool, isSelectionMode: Bool) {
        label.text = text ?? ""
        imageView.image = image
        isLoading ? spinner.startAnimating() : spinner.stopAnimating()
        checkmarkImageView.isHidden = !isSelectionMode || !isSelected
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        spinner.stopAnimating()
        imageView.image = nil
        label.text = nil
    }
}

private extension ImageTextCell {
    func updateCheckMark(animated: Bool) {
        let changes = {
            self.checkmarkImageView.isHidden = !self.isSelected
            self.checkmarkImageView.alpha = self.isSelected ? 1 : 0
            self.checkmarkImageView.transform = self.isSelected ? .identity : CGAffineTransform(scaleX: 0.8, y: 0.8)
        }
        animated ? UIView.animate(withDuration: 0.15, animations: changes) : changes()
    }
}
