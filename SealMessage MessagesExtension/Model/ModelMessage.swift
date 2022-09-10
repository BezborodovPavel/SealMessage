//
//  ModelMessage.swift
//  SealMessage MessagesExtension
//
//  Created by Павел on 02.09.2022.
//

import Foundation

struct ModelMessage {
    
    var modelMessage: ModelSealMessage
    var caption: String {
        
        var newCaptions = [String]()
        if let dateForCaption = modelMessage.openDate {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            dateFormatter.locale = Locale(identifier: "ru_RU")
            dateFormatter.doesRelativeDateFormatting = false
            let date = dateFormatter.string(from: dateForCaption)
            newCaptions.append("Дата вскрытия: \(date)")
        }
        
        return newCaptions.joined(separator: ", ")
    }
    
    var subCaption: String? {
        if !modelMessage.location.isEmpty() {
            return modelMessage.location.description
        } else {
            return nil
        }
    }
    
    var image: String {
        modelMessage.open ? "openMessage" : "closeMessage"
    }
    
    var queryItems: [URLQueryItem] {
        
        var queryItems = [URLQueryItem]()
        
        queryItems.append(URLQueryItem(name: "message", value: modelMessage.message))
        
        if let date = modelMessage.openDate {
            queryItems.append(URLQueryItem(name: "date", value: String(date.timeIntervalSince1970)))
        }
        
        if !modelMessage.location.isEmpty() {
            queryItems.append(URLQueryItem(name: "locationlatitude", value: String(modelMessage.location.latitude)))
            queryItems.append(URLQueryItem(name: "locationlongitude", value: String(modelMessage.location.longitude)))
            queryItems.append(URLQueryItem(name: "locationdescription", value: String(modelMessage.location.description)))
        }
        
        queryItems.append(URLQueryItem(name: "didSend", value: modelMessage.didSend.description))
        
        queryItems.append(URLQueryItem(name: "open", value: modelMessage.open.description))
        
        return queryItems
    }
}
