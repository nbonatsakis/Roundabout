//
//  Roundabout.swift
//  Pods
//
//  Created by Nicholas Bonatsakis on 12/28/16.
//
//

import UIKit
import ChimpKit
import PKHUD

public extension Roundabout {

    typealias RoundaboutMailChimpCompletion = ((_ didSubscribe: Bool) -> Void)

    func presentMailChimpSubscribe(from targetVC: UIViewController,
                                          key: String,
                                          listID: String,
                                          prompt: String = NSLocalizedString("Subscribe to our mailing list by providing your e-mail address below.", comment: ""),
                                          thanks: String = NSLocalizedString("Thanks for subscribing to our mailing list!", comment: ""),
                                          with completion: RoundaboutMailChimpCompletion? = nil) {
        let alert = UIAlertController(title: NSLocalizedString("Subscribe", comment: ""), message: prompt, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("E-mail Address", comment: "")
            textField.keyboardType = .emailAddress
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("Submit", comment: ""), style: .default, handler: { (action) in
            if let email = alert.textFields?[0].text, email.characters.count > 0 {
                HUD.show(.progress)
                self.subscribe(withEmail: email, key: key, listID: listID, with: { didSubscribe in
                    HUD.hide()
                    if didSubscribe {
                        self.showAlert(from: targetVC, title: NSLocalizedString("Thank You", comment: ""), message: thanks)
                    } else {
                        self.showAlert(from: targetVC, title: NSLocalizedString("Problem", comment: ""), message: NSLocalizedString("Could not subscrive to list, try again later.", comment: ""))
                    }

                    completion?(didSubscribe)
                })
            } else {
                self.showErrorAlert(from: targetVC)
            }
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))

        targetVC.present(alert, animated: true, completion: nil)
    }

}

fileprivate extension Roundabout {

    func showAlert(from targetVC: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: .cancel, handler: nil))
        targetVC.present(alert, animated: true, completion: nil)
    }

    func showErrorAlert(from targetVC: UIViewController) {
        let alert = UIAlertController(title: NSLocalizedString("E-mail Required", comment: ""), message: NSLocalizedString("You must enter a valid e-mail address in order to subscribe.", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: .cancel, handler: nil))
        targetVC.present(alert, animated: true, completion: nil)
    }

    func subscribe(withEmail email: String, key: String, listID: String, with completion: @escaping RoundaboutMailChimpCompletion) {
        let params: [String: Any] = [
            "id": listID,
            "email": ["email": email]
        ]
        ChimpKit.shared().callApiMethod("lists/subscribe", withApiKey: key, params: params) { (response, data, error) in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
    }

}
