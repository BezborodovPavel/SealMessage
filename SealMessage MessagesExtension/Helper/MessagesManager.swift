//
//  MessagesManager.swift
//  SealMessage MessagesExtension
//
//  Created by Павел on 31.08.2022.
//

import Foundation
import Messages

class MessagesManager {
    
    static func newModelFromMessage(from conversation: MSConversation) -> ModelSealMessage? {
    
        guard let msMessage = conversation.selectedMessage else {return nil}
        
        guard let url = msMessage.url else {return nil}
        
        guard let urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
                
        guard let queryItems = urlComponents.queryItems else { return nil }
        
        var modelFromMessage =  ModelSealMessage.newModel(from: queryItems)
        
        modelFromMessage.didSend = true
        
        return modelFromMessage
    }
    
    static func composeMessage(with model: ModelSealMessage, layoutImg: UIImage? = nil, session: MSSession? = nil) -> MSMessage? {
        
        var components = URLComponents()
        
        var queryItems = [URLQueryItem]()
        
        queryItems.append(URLQueryItem(name: "message", value: model.message))
        
        if let date = model.openDate {
            queryItems.append(URLQueryItem(name: "date", value: String(date.timeIntervalSince1970)))
        }
        
        let layout = MSMessageTemplateLayout()
        
//        guard let image = layoutImg else { return nil }
//        layout.image = image
        layout.caption = "Запечатанное сообщение"
        
        components.queryItems = queryItems
        
        let message = MSMessage(session: session ?? MSSession())
        
//        if let conversation = activeConversation, let msg = conversation.selectedMessage{
//            if msg.senderParticipantIdentifier == conversation.localParticipantIdentifier {
//                layout.caption =  "$\(msg.senderParticipantIdentifier.uuidString) rated it \(ratedItem.rating1!)"
//            }
//            else{
//                layout.caption =  "$\(msg.senderParticipantIdentifier.uuidString) rated it \(ratedItem.rating2!)"
//            }
//        }
    
        message.url = components.url ?? URL(string: "")
        message.layout = layout

        return message
    }
}
