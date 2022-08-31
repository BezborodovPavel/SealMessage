//
//  ModelSealMessage.swift
//  SealMessage MessagesExtension
//
//  Created by Павел on 29.08.2022.
//

import Foundation

struct ModelSealMessage {
    
    var message: String = ""
    var openDate: Date? = nil
    var location: (Int, Int)? = (latitude: 0, longitude:0)
    var didSend = false
    
    static func newModel(from queryItems: [URLQueryItem]) -> ModelSealMessage {
        
        var modelFromMessage = ModelSealMessage()
        
        let queryItems = queryItems.filter { queryItem in
            queryItem.value != nil
        }
        
        queryItems.forEach { queryItem in
            switch queryItem.name {
            case "message":
                modelFromMessage.message = queryItem.value!
            case "date":
                if let timeInterval = Double(queryItem.value!) {
                    modelFromMessage.openDate = Date(timeIntervalSince1970: timeInterval)
                }
            default:
                break
            }
        }
        
        return modelFromMessage
    }
}
