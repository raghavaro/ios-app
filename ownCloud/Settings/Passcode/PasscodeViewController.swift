//
//  PasscodeViewController.swift
//  ownCloud
//
//  Created by Javier Gonzalez on 03/05/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

let numberDigitsPasscode = 4
let passcodeKeychainAccount = "PasscodeKeychainAccount"
let passcodeKeychainPath = "PasscodeKeychainPath"

enum PasscodeMode {
    case addPasscodeFirstStep
    case addPasscodeSecondStep
    case unlockPasscode
    case deletePasscode
    case deletePasscodeError
    case addPasscodeFirstSetpAfterErrorOnSecond
}

class PasscodeViewController: UIViewController, Themeable {

    var passcodeFromFirstStep: String?
    var passcodeMode: PasscodeMode?

    @IBOutlet weak var messageLabel: UILabel?
    @IBOutlet weak var errorMessageLabel: UILabel?
    @IBOutlet weak var passcodeValueTextField: UITextField?

    @IBOutlet weak var number0Button: ThemeButton?
    @IBOutlet weak var number1Button: ThemeButton?
    @IBOutlet weak var number2Button: ThemeButton?
    @IBOutlet weak var number3Button: ThemeButton?
    @IBOutlet weak var number4Button: ThemeButton?
    @IBOutlet weak var number5Button: ThemeButton?
    @IBOutlet weak var number6Button: ThemeButton?
    @IBOutlet weak var number7Button: ThemeButton?
    @IBOutlet weak var number8Button: ThemeButton?
    @IBOutlet weak var number9Button: ThemeButton?

    @IBOutlet weak var cancelButton: ThemeButton?

    init(mode: PasscodeMode, passcodeFromFirstStep: String?) {
        super.init(nibName: "PasscodeViewController", bundle: nil)
        self.passcodeFromFirstStep = passcodeFromFirstStep
        self.passcodeMode = mode
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Theme.shared.register(client: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        Theme.shared.unregister(client: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.loadInterface()
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    // MARK: - Interface

    func loadInterface() {

        //Top message
        switch self.passcodeMode {
        case .addPasscodeFirstStep?:
            self.messageLabel?.text = "Insert your code".localized
            self.errorMessageLabel?.text = ""

        case .addPasscodeSecondStep?:
            self.messageLabel?.text = "Reinsert your code".localized
            self.errorMessageLabel?.text = ""

        case .unlockPasscode?:
            self.messageLabel?.text = "Insert your code".localized
            self.errorMessageLabel?.text = ""

        case .deletePasscode?:
            self.messageLabel?.text = "Delete code".localized
            self.errorMessageLabel?.text = ""

        case .deletePasscodeError?:
            self.messageLabel?.text = "Delete code".localized
            self.errorMessageLabel?.text = "Incorrect code".localized

        case .addPasscodeFirstSetpAfterErrorOnSecond?:
            self.messageLabel?.text = "Insert your code".localized
            self.errorMessageLabel?.text = "The insterted codes are not the same".localized


        default:
            break
        }
    }

    // MARK: - Actions

    @IBAction func cancelButton(sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func numberButton(sender: UIButton) {
        if let passcodeValue = self.passcodeValueTextField?.text {
            self.passcodeValueTextField?.text = passcodeValue + String(sender.tag)
        } else {
            self.passcodeValueTextField?.text = String(sender.tag)
        }

        self.passcodeValueHasChange(passcodeValue: (self.passcodeValueTextField?.text)!)
    }

    // MARK: - Passcode Flow

    func passcodeValueHasChange(passcodeValue: String) {
        print(passcodeValue)

        if passcodeValue.count >= numberDigitsPasscode {

            switch self.passcodeMode {
            case .addPasscodeFirstStep?, .addPasscodeFirstSetpAfterErrorOnSecond?:
                self.passcodeMode = .addPasscodeSecondStep
                self.passcodeFromFirstStep = passcodeValue
                self.passcodeValueTextField?.text = nil
                self.loadInterface()

            case .addPasscodeSecondStep?:
                if passcodeFromFirstStep == passcodeValue {
                    //Save to keychain
                    OCAppIdentity.shared().keychain.write(passcodeValue.data(using: .utf8), toKeychainItemForAccount: passcodeKeychainAccount, path: passcodeKeychainPath)
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.passcodeMode = .addPasscodeFirstSetpAfterErrorOnSecond
                    self.passcodeFromFirstStep = nil
                    self.passcodeValueTextField?.text = nil
                    self.loadInterface()
                }

            case .unlockPasscode?:
                self.dismiss(animated: true, completion: nil)

            case .deletePasscode?, .deletePasscodeError?:

                let passcodeFromKeychain = String(data: OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath), encoding: .utf8)

                if passcodeValue == passcodeFromKeychain {
                    OCAppIdentity.shared().keychain.removeItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath)
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.passcodeMode = .deletePasscodeError
                    self.passcodeValueTextField?.text = nil
                    self.loadInterface()
                }

            default:
                break
            }
        }
    }

    // MARK: - Themeing

    func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {

        self.view.backgroundColor = collection.tableBackgroundColor

        self.messageLabel?.applyThemeCollection(collection, itemStyle: .bigTitle, itemState: .normal)
        self.errorMessageLabel?.applyThemeCollection(collection)
        self.passcodeValueTextField?.applyThemeCollection(collection, itemStyle: .message, itemState: .normal)

        self.number0Button?.applyThemeCollection(collection, itemStyle: .neutral)
        self.number1Button?.applyThemeCollection(collection, itemStyle: .neutral)
        self.number2Button?.applyThemeCollection(collection, itemStyle: .neutral)
        self.number3Button?.applyThemeCollection(collection, itemStyle: .neutral)
        self.number4Button?.applyThemeCollection(collection, itemStyle: .neutral)
        self.number5Button?.applyThemeCollection(collection, itemStyle: .neutral)
        self.number6Button?.applyThemeCollection(collection, itemStyle: .neutral)
        self.number7Button?.applyThemeCollection(collection, itemStyle: .neutral)
        self.number8Button?.applyThemeCollection(collection, itemStyle: .neutral)
        self.number9Button?.applyThemeCollection(collection, itemStyle: .neutral)

        self.cancelButton?.applyThemeCollection(collection, itemStyle: .neutral)
    }
}
