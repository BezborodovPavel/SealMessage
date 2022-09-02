//
//  ModelMessage.swift
//  SealMessage MessagesExtension
//
//  Created by Павел on 02.09.2022.
//

import Foundation
import UIKit

struct ModelMessage {
    
    var modelMessage: ModelSealMessage
    var caption: String {
        
        var newCaptions = [String]()
        if let dateForCaption = modelMessage.openDate {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            dateFormatter.doesRelativeDateFormatting = true
            let date = dateFormatter.string(from: dateForCaption)
            newCaptions.append("Дата вскрытия: \(date)")
        }
        
        return newCaptions.joined(separator: ", ")
    }
    
    var image: UIImage {
        if modelMessage.open {
            return UIImage(named: "openMessage") ?? UIImage(systemName: "nosign")!
        } else {
            return UIImage(named: "closeMessage") ?? UIImage(systemName: "nosign")!
        }
    }
    
    var queryItems: [URLQueryItem] {
        
        var queryItems = [URLQueryItem]()
        
        queryItems.append(URLQueryItem(name: "message", value: modelMessage.message))
        
        if let date = modelMessage.openDate {
            queryItems.append(URLQueryItem(name: "date", value: String(date.timeIntervalSince1970)))
        }
        
        queryItems.append(URLQueryItem(name: "didSend", value: modelMessage.didSend.description))
        
        return queryItems
    }
}
