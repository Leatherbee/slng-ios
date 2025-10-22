//
//  ShareViewController.swift
//  ExplainSlangExtension
//
//  Created by Pramuditha Muhammad Ikhwan on 17/10/25.
//

import UIKit
import SwiftUI

class ShareViewController: UIViewController {
    
    private var sharedText: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        extractSharedText { [weak self] text in
            guard let self = self else { return }
            self.sharedText = text
            self.setupSwiftUIView()
        }
    }
    
    private func extractSharedText(completion: @escaping (String) -> Void) {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            completion("")
            return
        }
        
        if itemProvider.hasItemConformingToTypeIdentifier("public.plain-text") {
            itemProvider.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { (item, error) in
                var text = ""
                
                if let textData = item as? String {
                    text = textData
                } else if let textData = item as? Data {
                    text = String(data: textData, encoding: .utf8) ?? ""
                }
                
                DispatchQueue.main.async {
                    completion(text)
                }
            }
        } else {
            completion("")
        }
    }
    
    private func setupSwiftUIView() {
        let hostingController = UIHostingController(
            rootView: ShareExtensionView(
                sharedText: sharedText,
                onDismiss: { [weak self] in
                    self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                }
            )
        )
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)
    }
}
