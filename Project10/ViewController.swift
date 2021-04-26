//
//  ViewController.swift
//  Project10
//
//  Created by Paul Richardson on 26/04/2021.
//

import UIKit

class ViewController: UICollectionViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPerson))
	}

	@objc func addPerson() {

	}

	// MARK: - Collection View Data Source

	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 10
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Person", for: indexPath) as? PersonCell else {
			fatalError("Unable to dequeue PersonCell")
		}
		return cell
	}

}

