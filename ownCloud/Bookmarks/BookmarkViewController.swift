//
//  BookmarkViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.03.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2018, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK
import ownCloudUI

enum BookmarkViewControllerMode {
    case add
    case edit
}

let BookmarkDefaultURLKey = "default-url"
let BookmarkURLEditableKey = "url-editable"

class BookmarkViewController: StaticTableViewController, OCClassSettingsSupport {

    public var mode : BookmarkViewControllerMode = .add
    public var bookmarkToAdd : OCBookmark?
    public var connection: OCConnection?
    private var authMethodType: OCAuthenticationMethodType?

    static func classSettingsIdentifier() -> String! {
        return "bookmark"
    }

    static func defaultSettings(forIdentifier identifier: String!) -> [String : Any]! {
        return [ BookmarkDefaultURLKey : "",
                 BookmarkURLEditableKey : true
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.bounces = false

            switch self.mode {
            case .add:
                print("Add mode")
                self.navigationItem.title = "Add Server".localized
                self.addServerUrl()
                self.addContinueButton(action: self.continueButtonAction)
            case .edit:
                print("Edit mode")
                self.navigationItem.title = "Edit Server".localized
            }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.sectionForIdentifier("server-url-section")?.row(withIdentifier: "server-url-textfield")?.textField?.becomeFirstResponder()
    }

    private func addServerUrl() {

        let serverURLSection: StaticTableViewSection = StaticTableViewSection(headerTitle:"Server URL".localized, footerTitle: nil, identifier: "server-url-section")

        let serverURLRow: StaticTableViewRow = StaticTableViewRow(textFieldWithAction: nil,
                                                                  placeholder: "https://example.com".localized,
                                                                  value: self.classSetting(forOCClassSettingsKey: BookmarkDefaultURLKey) as? String ?? "" ,
                                                                  keyboardType: .default,
                                                                  autocorrectionType: .no,
                                                                  autocapitalizationType: .none,
                                                                  enablesReturnKeyAutomatically: false,
                                                                  returnKeyType: .continue,
                                                                  identifier: "server-url-textfield")
        serverURLRow.cell?.isUserInteractionEnabled = self.classSetting(forOCClassSettingsKey: BookmarkURLEditableKey) as? Bool ?? true

        serverURLSection.add(rows: [serverURLRow])
        addSection(serverURLSection, animated: false)
    }

    private func addContinueButton(action: @escaping StaticTableViewRowAction) {

        let continueButtonSection = StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: "continue-button-section", rows: [
            StaticTableViewRow(buttonWithAction: action, title: "Continue".localized,
               style: .proceed,
               identifier: "continue-button-row")
            ])

        self.addSection(continueButtonSection, animated: false)
    }

    private func addServerName() {

        var serverName = ""
        switch self.mode {
        case .add:
            break
        case .edit:
            if let name = self.bookmarkToAdd?.name {
                serverName = name
            }
        }

        let section = StaticTableViewSection(headerTitle: "Name".localized, footerTitle: nil, identifier: "server-name-section", rows: [
            StaticTableViewRow(textFieldWithAction: nil,
                               placeholder: "Example Server".localized,
                               value: serverName,
                               secureTextEntry: false,
                               keyboardType: .default,
                               autocorrectionType: .yes, autocapitalizationType: .sentences, enablesReturnKeyAutomatically: true, returnKeyType: .done, identifier: "server-name-textfield")

            ])

        self.insertSection(section, at: 0, animated: true)
    }

    private func addCertificateDetails(certificate: OCCertificate) {
        let section =  StaticTableViewSection(headerTitle: "Certificate Details".localized, footerTitle: nil)
        section.add(rows: [
            StaticTableViewRow(rowWithAction: {(staticRow, _) in
				staticRow.section?.viewController?.navigationController?.pushViewController(OCCertificateViewController(certificate: certificate), animated: true)
            }, title: "Show Certificate Details".localized, accessoryType: .disclosureIndicator, identifier: "certificate-details-button")
        ])
        self.addSection(section, animated: true)
    }

    private func addConnectButton() {
        let connectButtonSection = StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: "connect-button-section", rows: [
            StaticTableViewRow(buttonWithAction: { (row, _) in

                var options: [OCAuthenticationMethodKey : Any] = Dictionary()
                var method: String = OCAuthenticationMethodOAuth2Identifier

                if self.authMethodType != nil && self.authMethodType == OCAuthenticationMethodType.passphrase {

                    method = OCAuthenticationMethodBasicAuthIdentifier

                    let username: String? = self.sectionForIdentifier("passphrase-auth-section")?.row(withIdentifier: "passphrase-username-textfield-row")?.value as? String
                    let password: String?  = self.sectionForIdentifier("passphrase-auth-section")?.row(withIdentifier: "passphrase-password-textfield-row")?.value as? String

                    options[.usernameKey] = username!
                    options[.passphraseKey] = password!

                }

                options[.presentingViewControllerKey] = self

                self.connection?.generateAuthenticationData(withMethod: method, options: options, completionHandler: { (error, authenticationMethodIdentifier, authenticationData) in

                    if error == nil {
                        let serverName = self.sectionForIdentifier("server-name-section")?.row(withIdentifier: "server-name-textfield")?.value as? String
                        self.bookmarkToAdd?.name = (serverName != nil && serverName != "") ? serverName: self.bookmarkToAdd!.url.absoluteString
                        self.bookmarkToAdd?.authenticationMethodIdentifier = authenticationMethodIdentifier
                        self.bookmarkToAdd?.authenticationData = authenticationData
                        BookmarkManager.shared.addBookmark(self.bookmarkToAdd!)

                        DispatchQueue.main.async {
                            self.navigationController?.popViewController(animated: true)
                        }
                    } else {
                        DispatchQueue.main.async {
                            let issuesVC = ConnectionIssueViewController(issue: OCConnectionIssue(forError: error, level: OCConnectionIssueLevel.error, issueHandler: nil))
                            issuesVC.modalPresentationStyle = .overCurrentContext
                            self.present(issuesVC, animated: true, completion: nil)
                        }
                    }
                })
            }, title: "Connect".localized,
               style: .proceed,
               identifier: nil)])

        self.addSection(connectButtonSection)

    }

    private func addDeleteAuthDataButton() {
        if let section = self.sectionForIdentifier("connect-button-section") {
            section.add(rows: [
                StaticTableViewRow(buttonWithAction: { (_, _) in
                    if let bookmark = self.bookmarkToAdd {
                        bookmark.authenticationData = nil
                    }

                }, title: "Delete Authentication Data".localized, style: .destructive, identifier: "delete-auth-button")
                ])
        }
    }

    private func removeContinueButton() {
        if let buttonSection = self.sectionForIdentifier("continue-button-section") {
            self.removeSection(buttonSection)
        }
    }

    private func showBasicAuthCredentials(username: String?, password: String?) {
        let section = StaticTableViewSection(headerTitle:"Authentication".localized, footerTitle: nil, identifier: "passphrase-auth-section", rows:
            [ StaticTableViewRow(textFieldWithAction: nil,
                                 placeholder: "Username".localized,
                                 value: username ?? "",
                                 secureTextEntry: false,
                                 keyboardType: .emailAddress,
                                 autocorrectionType: .no,
                                 autocapitalizationType: UITextAutocapitalizationType.none,
                                 enablesReturnKeyAutomatically: true,
                                 returnKeyType: .continue,
                                 identifier: "passphrase-username-textfield-row"),

              StaticTableViewRow(textFieldWithAction: nil, placeholder: "Password".localized,
                                 value: password ?? "",
                                 secureTextEntry: true,
                                 keyboardType: .emailAddress,
                                 autocorrectionType: .no,
                                 autocapitalizationType: .none,
                                 enablesReturnKeyAutomatically: true,
                                 returnKeyType: .go,
                                 identifier: "passphrase-password-textfield-row")
            ])
        self.insertSection(section, at: self.sections.count-1, animated: true)
    }

    lazy private var continueButtonAction: StaticTableViewRowAction  = { (row, _) in

        var username: NSString?
        var password: NSString?
        var afterURL: String = ""

        afterURL = self.sectionForIdentifier("server-url-section")?.row(withIdentifier: "server-url-textfield")?.value as? String ?? ""

        var protocolAppended: ObjCBool = false

        if let bookmark: OCBookmark = OCBookmark(for: NSURL(username: &username, password: &password, afterNormalizingURLString: afterURL, protocolWasPrepended: &protocolAppended) as URL),
            let newConnection: OCConnection = OCConnection(bookmark: bookmark) {

            self.bookmarkToAdd = bookmark
            self.connection = newConnection

            newConnection.prepareForSetup(options: nil, completionHandler: { (issuesFromSDK, _, _, preferredAuthMethods) in

                if let issues = issuesFromSDK?.issuesWithLevelGreaterThanOrEqual(to: OCConnectionIssueLevel.warning),
                    issues.count > 0 {
                    DispatchQueue.main.async {
                        let issuesVC = ConnectionIssueViewController(issue: issuesFromSDK!)
                        issuesVC.modalPresentationStyle = .overCurrentContext
                        self.present(issuesVC, animated: true, completion: nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.approveButtonAction(preferedAuthMethods: preferredAuthMethods!, issuesFromSDK: issuesFromSDK!, username: username as String?, password: password as String?)
                    }
                }

            })
        }
    }

    private func approveButtonAction(preferedAuthMethods: [String], issuesFromSDK: OCConnectionIssue?, username: String?, password: String?) {

        self.sectionForIdentifier("server-url-section")?.row(withIdentifier: "server-url-textfield")?.value = self.bookmarkToAdd?.url.absoluteString

        if let preferedAuthMethod = preferedAuthMethods.first as String? {

            self.authMethodType = OCAuthenticationMethod.registeredAuthenticationMethod(forIdentifier: preferedAuthMethod).type()

            DispatchQueue.main.async {
                self.addServerName()
                if let certificateIssue = issuesFromSDK?.issues.filter({ $0.type == .certificate}).first {
                    self.addCertificateDetails(certificate: certificateIssue.certificate)
                }

                if self.authMethodType == .passphrase {
                    self.showBasicAuthCredentials(username: username, password:password)
                }
                self.removeContinueButton()
                self.addConnectButton()
                self.tableView.reloadData()
            }
        }
    }
}
