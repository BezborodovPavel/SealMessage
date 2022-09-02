//
//  ModelSealMessage.swift
//  SealMessage MessagesExtension
//
//  Created by Павел on 29.08.2022.
//

import Foundation
import Messages

struct ModelSealMessage {
    
    var message: String = ""
    var openDate: Date? = nil
    var location: (Int, Int)? = (latitude: 0, longitude:0)
    var didSend = false
    var open = false
    var senderIsLocal = true
    
}

extension ModelSealMessage {
    
    init?(from queryItems: [URLQueryItem]) {
        
        var message = ""
        var openDate: Date?
        
        for queryItem in queryItems {
            
            guard let value = queryItem.value else { continue }
            
            switch queryItem.name {
            case "message":
                message = value
            case "date":
                if let timeInterval = Double(value) {
                    openDate = Date(timeIntervalSince1970: timeInterval)
                }
            case "didSend":
                if let send = Bool(value) {
                    didSend = send
                }
            default:
                break
            }
        }
        
        self.message = message
        self.openDate = openDate
    }
    
    init?(message: MSMessage?) {
        guard let messageURL = message?.url else { return nil }
        guard let urlComponents = NSURLComponents(url: messageURL, resolvingAgainstBaseURL: false) else { return nil }
        guard let queryItems = urlComponents.queryItems else { return nil }
        self.init(from: queryItems)
    }
    
}
