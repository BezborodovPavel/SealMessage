//
//  DateViewController.swift
//  SealMessage MessagesExtension
//
//  Created by Павел on 30.08.2022.
//

import UIKit

protocol childrenMessageVC: UIViewController {
    var model: ModelSealMessage! {get set}
}

class DateViewController: UIViewController, childrenMessageVC  {

    var model: ModelSealMessage!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var onOffSwitch: UISwitch!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.minimumDate = Date.now
        update()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateNotification(withNotification:)),
            name: NSNotification.Name(rawValue: "model updated"),
            object: nil)
    }

    @IBAction func onOffSwitchChanged() {
        model.openDate = onOffSwitch.isOn ? datePicker.date : nil
        sendNotification()
    }
    
    @IBAction func datePickerChanged() {
        model.openDate = onOffSwitch.isOn ? roundDate(date: datePicker.date) : nil
        
        sendNotification()
    }
    
    private func roundDate(date: Date) -> Date {
        
        let calendar = Calendar.current
        
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)

        components.second = 0
        
        return calendar.date(from: components) ?? date
        
    }
    
    @objc private func updateNotification(withNotification notification: Notification) {        
        guard
            let userInfo = notification.userInfo,
            let modelFromNotification = userInfo["model"] as? ModelSealMessage
            else { fatalError() }
        
        model = modelFromNotification
        update()
    }
    
    private func update() {
        
        onOffSwitch.isEnabled = !model.didSend
        datePicker.date = model.openDate ?? Date.now
        datePicker.locale = Locale(identifier: "ru_RU")
        datePicker.isEnabled = onOffSwitch.isOn
        titleLabel.alpha = onOffSwitch.isOn ? 1 : 0.5
    }

    private func sendNotification() {
        
        NotificationCenter.default.post(
            name: NSNotification.Name("main view need updated"),
            object: self,
            userInfo: ["model": model!]
        )
    }
    
}
