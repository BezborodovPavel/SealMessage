//
//  MessagesViewController.swift
//  SealMessage MessagesExtension
//
//  Created by Павел on 27.08.2022.
//

import UIKit
import Messages

protocol MessagesViewControllerDelegate {
    func sendMessage(from controller: ExpandedViewController, needSend: Bool)
    func expandedVC()
}

class MessagesViewController: MSMessagesAppViewController, UITextViewDelegate {
    
    // MARK: - Conversation Handling
    override func willBecomeActive(with conversation: MSConversation) {
        if presentationStyle == .compact {
            presentViewController(for: conversation, with: presentationStyle)
        } else {
            presentViewController(for: conversation, with: presentationStyle)
        }
    }
   
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        removeAllChildViewControllers()
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        guard let conversation = activeConversation else { fatalError("Expected an active converstation") }
        presentViewController(for: conversation, with: presentationStyle)
    }
    
    fileprivate func composeMessage(with model: ModelSealMessage, session: MSSession? = nil) -> MSMessage {
        
        let modelMessage = ModelMessage(modelMessage: model)
        
        var components = URLComponents()
        components.queryItems = modelMessage.queryItems
        
        let layout = MSMessageTemplateLayout()
        layout.image = modelMessage.image
        layout.caption = modelMessage.caption
        layout.subcaption = modelMessage.subCaption
        
        let message = MSMessage(session: session ?? MSSession())
        
        guard let url = components.url else {fatalError("Не удалось сформировать URL для отправки сообщения")}
        message.url = url
        message.layout = layout
        
        return message
    }
}

extension MessagesViewController {
    
    private func presentViewController(for conversation: MSConversation, with presentationStyle: MSMessagesAppPresentationStyle) {

        removeAllChildViewControllers()
        
        let controller: UIViewController
        if presentationStyle == .compact {
            controller = instantiateCompactVC()
        } else {
            let model = ModelSealMessage(message: conversation.selectedMessage) ?? ModelSealMessage()
            
            if let msg = conversation.selectedMessage{
                model.senderIsLocal = msg.senderParticipantIdentifier == conversation.localParticipantIdentifier
            }
            controller = instantiateExpandedVC(with: model)
        }
 
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
    
    private func instantiateCompactVC() -> UIViewController {

        guard let controller = storyboard?.instantiateViewController(withIdentifier: String(describing: CompactViewController.self)) as? CompactViewController else {fatalError("Unable to instantiate an CompactViewController from the storyboard")}

        
        controller.delegate = self
        
        return controller
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
            
            guard let conversation = activeConversation else { fatalError("Expected a conversation") }
            
            guard let model = controller.model else { fatalError("Expected the controller to be displaying an model message") }
            
            model.didSend = true
            
            let message = composeMessage(with: model, session: conversation.selectedMessage?.session)
            
            conversation.insert(message) { error in
                if error != nil {
                    fatalError("Can't insert message!")
                }
            }
        }
        
        dismiss()
    }
    
    func expandedVC() {
        requestPresentationStyle(.expanded)
    }
}
