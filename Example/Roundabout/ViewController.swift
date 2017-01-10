//
//  ViewController.swift
//  Roundabout
//
//  Created by Nick Bonatsakis on 12/28/2016.
//  Copyright (c) 2016 Nick Bonatsakis. All rights reserved.
//

import UIKit
import Roundabout

class ViewController: UITableViewController {

    @IBOutlet var infoLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        infoLabel.text = Roundabout.shared.userInfoString
    }

    @IBAction func shareTapped() {
        Roundabout.shared.presentShare(from: self)
    }

    @IBAction func feedbackTapped() {
        Roundabout.shared.presentFeedback(from: self)
    }

    @IBAction func moreAppsTapped() {
        Roundabout.shared.presentMoreApps(from: self)
    }

}

