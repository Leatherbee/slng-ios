//
//  KeyboardViewController.swift
//  KeyboardSlangExtension
//
//  Created by Filza Rizki Ramadhan on 22/10/25.
//

import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {
    private var hostingController: UIHostingController<SlangKeyboardView>?
     
    private var keyboardHeight: CGFloat = 270
    
    override func viewDidLoad() {
        super.viewDidLoad()
         
        let root = SlangKeyboardView(
            insertText: { [weak self] text in
                guard let self else { return }
                self.textDocumentProxy.insertText(text)
            },
            deleteText: { [weak self] in
                guard let self, self.textDocumentProxy.hasText else { return }
                self.textDocumentProxy.deleteBackward()
            },
            keyboardHeight: keyboardHeight,
            backgroundColor: .clear, needsInputModeSwitchKey: self.needsInputModeSwitchKey,
            nextKeyboardAction: #selector(self.handleInputModeList(from:with:))
        )
        
        let hosting = UIHostingController(rootView: root)
        hosting.view.backgroundColor = .clear
         
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)
         
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        self.hostingController = hosting
         
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: keyboardHeight)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
}
