//
//  ViewController.swift
//  Project10
//
//  Created by Paul Richardson on 26/04/2021.
//

import UIKit

class ViewController: UICollectionViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

	var people = [Person]()

	override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPerson))
	}

	@objc func addPerson() {
		let picker = UIImagePickerController()
		if UIImagePickerController.isSourceTypeAvailable(.camera) {
			picker.sourceType = .camera
		}
		picker.allowsEditing = true
		picker.delegate = self
		present(picker, animated: true)
	}

	func save() {
		let jsonEncoder = JSONEncoder()
		if let savedData = try? jsonEncoder.encode(people) {
			let defaults = UserDefaults.standard
			defaults.set(savedData, forKey: "people")
		} else {
			print("Failed to save data.")
		}
	}

	// MARK: Image Picker Delegate Methods

	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		guard let image = info[.editedImage] as? UIImage else { return }

		let imageName = UUID().uuidString
		let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)

		if let jpegData = image.jpegData(compressionQuality: 0.8) {
			try? jpegData.write(to: imagePath)
		}

		let person = Person(name: "Unknown", image: imageName)
		people.append(person)
		collectionView.reloadData()
		save()
		dismiss(animated: true)
	}

	func getDocumentsDirectory() -> URL {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		return paths[0]
	}

	// MARK: - Collection View Data Source

	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return people.count
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Person", for: indexPath) as? PersonCell else {
			fatalError("Unable to dequeue PersonCell")
		}

		let person = people[indexPath.item]
		cell.name.text = person.name

		let path = getDocumentsDirectory().appendingPathComponent(person.image)
		cell.imageView.image = UIImage(contentsOfFile: path.path)

		cell.imageView.layer.borderColor = UIColor(white: 0, alpha: 0.3).cgColor
		cell.imageView.layer.borderWidth = 2
		cell.imageView.layer.cornerRadius = 3
		cell.layer.cornerRadius = 7

		return cell
	}

	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {


		let ac = UIAlertController(title: "Do you want to rename or delete?", message: nil, preferredStyle: .alert)
		ac.addAction(UIAlertAction(title: "Rename", style: .default) { action in
			let person = self.people[indexPath.item]
			self.rename(person)
		})
		ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { action in
			self.people.remove(at: indexPath.item)
			self.collectionView.reloadData()
			self.save()
		})
		ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

		present(ac, animated: true)

	}

	fileprivate func rename(_ person: Person) {
		let ac = UIAlertController(title: "Rename person", message: nil, preferredStyle: .alert)
		ac.addTextField { textfield in
			textfield.text = person.name
			textfield.clearButtonMode = .always
			textfield.autocapitalizationType = .sentences
		}
		ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak self, weak ac] _ in
			guard let newName = ac?.textFields?[0].text  else { return }
			person.name = newName
			self?.collectionView.reloadData()
			self?.save()
		})

		present(ac, animated: true)
	}

}

