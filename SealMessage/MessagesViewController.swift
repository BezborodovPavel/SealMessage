//
//  MessagesViewController.swift
//  SealMessage MessagesExtension
//
//  Created by Павел on 27.08.2022.
//

import UIKit
import MessageUI
import Messages

protocol MessagesViewControllerDelegate {
    func sendMessage(from controller: ExpandedViewController, needSend: Bool)
    func expandedVC()
}

class MessagesViewController: UIViewController, UITextViewDelegate, MFMessageComposeViewControllerDelegate {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presentViewController()
    }
    
    fileprivate func composeMessage(with model: ModelSealMessage) -> MSMessage {
        
        let modelMessage = ModelMessage(modelMessage: model)
        
        var components = URLComponents()
        components.queryItems = modelMessage.queryItems
        
        let layout = MSMessageTemplateLayout()
        layout.image = UIImage(named: modelMessage.image) ?? UIImage(systemName: "nosign")
        layout.caption = modelMessage.caption
        layout.subcaption = modelMessage.subCaption
        
        let message = MSMessage(session: MSSession())
        
        guard let url = components.url else {
            fatalError("Не удалось сформировать URL для отправки сообщения")}
        message.url = url
        message.layout = layout
        
        return message
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
}

extension MessagesViewController {
    
    private func presentViewController() {

        removeAllChildViewControllers()
        
        let controller: UIViewController

        let model = ModelSealMessage()
        
        controller = instantiateExpandedVC(with: model)
 
        addChild(controller)
        controller.view.frame = view.bounds
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        
        NSLayoutConstraint.activate([
            controller.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            controller.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            controller.view.topAnchor.constraint(equalTo: view.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        
        controller.didMove(toParent: self)
    }
    
    private func instantiateExpandedVC(with model: ModelSealMessage) -> UIViewController {
        
        guard let controller = storyboard?.instantiateViewController(withIdentifier: String(describing: ExpandedViewController.self)) as? ExpandedViewController else {fatalError("Unable to instantiate an ExpandedViewController from the storyboard")}
        
        controller.delegate = self
        controller.model = model
        
        return controller
    }
}

extension MessagesViewController: MessagesViewControllerDelegate {
    
    func sendMessage(from controller: ExpandedViewController, needSend: Bool) {
        
        if needSend {
            
            guard MFMessageComposeViewController.canSendText() else {
                showAlert(with: "MFMessageComposeViewController - can not send text")
                return}
            
            guard let model = controller.model else {
                showAlert(with: "Expected the controller to be displaying an model message")
                fatalError("Expected the controller to be displaying an model message") }
            model.didSend = true
            
            let message = composeMessage(with: model)

            let composeVC = MFMessageComposeViewController()
            
            composeVC.messageComposeDelegate = self

            composeVC.message = message
        
            controller.present(composeVC, animated: true)
       }
        
        dismiss(animated: true)
    }
    
    func expandedVC() {
        presentViewController()
    }
    
    private func showAlert(with text: String) {
        
        let alertVC = UIAlertController(title: "Ошибка", message: text, preferredStyle: .alert)
        let action = UIAlertAction(title: "Закрыть", style: .cancel) { _ in
                self.dismiss(animated: true)
        }
        alertVC.addAction(action)
        show(alertVC, sender: self)
        
    }
 }
