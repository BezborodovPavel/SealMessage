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
    
}
