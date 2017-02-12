//
//  Roundabout.swift
//  Pods
//
//  Created by Nicholas Bonatsakis on 12/28/16.
//
//

import UIKit
import MessageUI
import StoreKit

public struct RoundaboutConfig {

    let appName: String
    let appID: String
    let feedbackEmail: String
    let affiliateToken: String?
    let iTunesDeveloperID: String?

    public var appURL: URL {
        var URLString = "http://itunes.apple.com/app/id\(appID)"
        if let affiliateToken = affiliateToken {
            URLString += "?at=\(affiliateToken)"
        }

        return URL(string: URLString)!
    }

    public init(appName: String,
                appID: String,
                feedbackEmail: String,
                affiliateToken: String? = nil,
                iTunesDeveloperID: String? = nil) {
        self.appName = appName
        self.appID = appID
        self.feedbackEmail = feedbackEmail
        self.affiliateToken = affiliateToken
        self.iTunesDeveloperID = iTunesDeveloperID
    }
}

public class Roundabout: NSObject {

    public static let shared = Roundabout()

    private var config: RoundaboutConfig?

    public func configure(_ config: RoundaboutConfig) {
        self.config = config
    }

    // MARK: Actions

    public func presentShare(from targetVC: UIViewController,
                                    sourceView: UIView? = nil,
                                    sourceRect: CGRect? = nil) {
        guard let config = self.config else {
            onMissingConfig()
            return
        }

        let message = String(format: NSLocalizedString("Check out %@ for iOS!", comment: ""), config.appName)
        let activityVC = UIActivityViewController(activityItems: [message, config.appURL],
                                                  applicationActivities: nil)

        if let sourceView = sourceView, let sourceRect = sourceRect {
            activityVC.popoverPresentationController?.sourceView = sourceView
            activityVC.popoverPresentationController?.sourceRect = sourceRect
        }

        activityVC.completionWithItemsHandler = { (type, completed, _, error) in
            if completed {
                self.alert(from: targetVC,
                      title: NSLocalizedString("Thanks", comment: ""),
                      message: NSLocalizedString("Thank you for sharing, have a great day!", comment: ""))
            }
        }

        targetVC.present(activityVC, animated: true, completion: nil)
    }

    public func presentFeedback(from targetVC: UIViewController) {
        guard let config = self.config else {
            onMissingConfig()
            return
        }

        let mailVC = MFMailComposeViewController()
        mailVC.setToRecipients([config.feedbackEmail])
        mailVC.setSubject("\(config.appName) Feedback")
        let infoData = userInfoString.data(using: String.Encoding.utf8)
        mailVC.addAttachmentData(infoData!, mimeType: "text/plain", fileName: "device_oinfo.txt")
        mailVC.mailComposeDelegate = self

        targetVC.present(mailVC, animated: true, completion: nil)
    }

    public func presentMoreApps(from targetVC: UIViewController) {
        guard let config = self.config else {
            onMissingConfig()
            return
        }

        guard let developerID = config.iTunesDeveloperID else {
            fatalError("You must specify a valid iTunes Developer ID in order to hsow a More Apps screen.")
        }

        let productsVC = SKStoreProductViewController()
        productsVC.delegate = self

        var params = [
            SKStoreProductParameterITunesItemIdentifier: developerID
        ]

        if let affiliateToken = config.affiliateToken {
            params[SKStoreProductParameterAffiliateToken] = affiliateToken
        }

        productsVC.loadProduct(withParameters: params) { (success, error) in
        }

        targetVC.present(productsVC, animated: true, completion: nil)
    }

    // MARK: Info

    public var system: String {
        return UIDevice.current.systemName + " " + UIDevice.current.systemVersion
    }

    public var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    public var appBuild: String {
        return Bundle.main.infoDictionary?[kCFBundleVersionKey as! String] as? String ?? "Unknown"
    }

    public var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        return identifier
    }

    public var userInfoString: String {
        return  "\(config?.appName ?? "Unknown App")\n" +
                "\(system)\n" +
                "App Version: \(appVersion) (\(appBuild))\n" +
                "Device Model: \(deviceModel)"

    }

}

extension Roundabout: MFMailComposeViewControllerDelegate {

    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        guard let parentVC = controller.presentingViewController else {
            controller.dismiss(animated: true, completion: nil)
            return
        }

        controller.dismiss(animated: true) {
            if result != .cancelled {
                self.alert(from: parentVC,
                           title: NSLocalizedString("Thanks", comment: ""),
                           message: NSLocalizedString("Thank you for sending us feedback.", comment: ""))
            }
        }
    }
    
}

extension Roundabout: SKStoreProductViewControllerDelegate {

    public func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }

}

private extension Roundabout {

    func onMissingConfig() {
        fatalError("Roundabout not configured. Please call Roundabout.configure with a config instance first.")
    }

    func alert(from targetVC: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        targetVC.present(alert, animated: true, completion: nil)
    }

}
