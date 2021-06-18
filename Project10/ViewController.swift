//
//  ViewController.swift
//  Project10
//
//  Created by Paul Richardson on 26/04/2021.
//

import UIKit
import LocalAuthentication

class ViewController: UICollectionViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

	var people = [Person]()
	var isLocked = true
	var addButton: UIBarButtonItem!
	var authenticateButton: UIBarButtonItem!

	override func viewDidLoad() {
		super.viewDidLoad()
		addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPerson))
		authenticateButton = UIBarButtonItem(title: "Authenticate", style: .plain, target: self, action: #selector(authenticate))
		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
		notificationCenter.addObserver(self, selector: #selector(authenticate), name: UIApplication.willEnterForegroundNotification, object: nil)

		if isLocked {
			authenticate()
		} else {
			navigationItem.setLeftBarButton(addButton, animated: true)
			loadData()
		}

	}

	@objc func didEnterBackground() {
		isLocked = true
		save()
		people.removeAll()
		collectionView.reloadData()
		navigationItem.setLeftBarButton(nil, animated: true)
	}

	fileprivate func loadData() {
		let defaults = UserDefaults.standard
		if let savedPeople = defaults.object(forKey: "people") as? Data {
			let jsonDecoder = JSONDecoder()
			do {
				try people = jsonDecoder.decode([Person].self, from: savedPeople)
			} catch {
				print("Failed to load people.")
			}
		}
	}

	@objc func authenticate() {
		let context = LAContext()
		var error: NSError?
		if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
			context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Please authenticate to access the data.") { [weak self] success, authenticationError in
				DispatchQueue.main.async {
					if success {
						self?.isLocked = false
						self?.navigationItem.setLeftBarButton(self?.addButton, animated: true)
						self?.navigationItem.setRightBarButton(nil, animated: true)
						self?.loadData()
						self?.collectionView.reloadData()
					} else {
						if let error = authenticationError {
							switch error._code {
							case LAError.Code.userCancel.rawValue:
								self?.navigationItem.setRightBarButton(self?.authenticateButton, animated: true)
							default:
								let ac = UIAlertController(title: "Authentication failed.", message: "Your identity could not be verified; please try again.", preferredStyle: .alert)
								ac.addAction(UIAlertAction(title: "OK", style: .default))
								self?.present(ac, animated: true) {
									self?.navigationItem.setRightBarButton(self?.authenticateButton, animated: true)
								}
							}
						}
					}
				}
			}
		} else {
			let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configure for biometric authentication; please try again.", preferredStyle: .alert)
			ac.addAction(UIAlertAction(title: "OK", style: .default))
			present(ac, animated: true) { [weak self] in
				self?.navigationItem.setRightBarButton(self?.authenticateButton, animated: true)
			}
		}
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
		guard !isLocked else { return }
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

