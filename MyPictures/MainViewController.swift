//
//  MainViewController.swift
//  MyPictures
//
//  Created by Joana Valadao on 2025-08-27.
//

import UIKit

class MainViewController: UIViewController {

    var imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .systemBlue
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        
        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        Task {
            do {
                let x = try await ImageService().addRandomImage()
                imageView.image = UIImage(data: (try x?.loadImageData())!)
            } catch {
                print(error)
            }
        }
        
    }


}

