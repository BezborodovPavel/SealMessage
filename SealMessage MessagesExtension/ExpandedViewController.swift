//
//  ExpandedViewController.swift
//  SealMessage MessagesExtension
//
//  Created by Павел on 02.09.2022.
//

import UIKit

class ExpandedViewController: UIViewController, UITextViewDelegate {

    var delegate: MessagesViewControllerDelegate?
    var model: ModelSealMessage!

    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    
    private var currentViewControllerIndex = 0
    private var pagesViewControllers: [UIViewController]!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI()
        setupPageViewController()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateNotification(withNotification:)),
            name: NSNotification.Name(rawValue: "main view need updated"),
            object: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super .touchesBegan(touches, with: event)
        view.endEditing(true)
    }
    
    @IBAction func sendButtonPress() {
        model.didSend = true
        delegate?.sendMessage(from: self)
    }
    
    private func getStringCondition() -> String {
        
        var stringCondition = ""
    
        if let dateCondition = model.openDate {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            dateFormatter.doesRelativeDateFormatting = true
            let date = dateFormatter.string(from: dateCondition)
            stringCondition = "Открыть не ранее \(date)"
        }
        
        return stringCondition
    }
    
    @objc private func updateNotification(withNotification notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let modelFromNotification = userInfo["model"] as? ModelSealMessage
            else { fatalError() }
        
        model = modelFromNotification
        updateUI()
    }
}

// MARK: UI
extension ExpandedViewController {
    
    private func setupPageViewController() {
        
        setPagesViewControllers()
        
        guard let pageViewController = storyboard?.instantiateViewController(withIdentifier: String(describing: PageViewController.self)) as? PageViewController else {return}
        
        pageViewController.delegate = self
        pageViewController.dataSource = self
        
        addChild(pageViewController)
        pageViewController.didMove(toParent: self)
        
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pageViewController.view)
        
        pageViewController.view.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        pageViewController.view.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        pageViewController.view.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        pageViewController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        pageViewController.setViewControllers([pagesViewControllers.first!], direction: .forward, animated: true)
                
    }
    
    private func setPagesViewControllers() {
        var controllers =  [childrenMessageVC]()
        
        if let dateViewController = storyboard?.instantiateViewController(withIdentifier: String(describing: DateViewController.self)) as? childrenMessageVC {
            controllers.append(dateViewController)
            dateViewController.model = model
        }
        
        if let mapViewController = storyboard?.instantiateViewController(withIdentifier: String(describing: MapViewController.self)) as? childrenMessageVC {
            controllers.append(mapViewController)
            mapViewController.model = model
        }
        
        pagesViewControllers =  controllers
    }
    
    private func updateUI() {
        
        messageTextView.text = model.message
        messageTextView.isEditable = !model.didSend
        sendButton.isEnabled = !messageTextView.text.isEmpty

        setPlaceholder()
        
        conditionLabel.text = getStringCondition()
       
        if !model.senderIsLocal {
            messageTextView.layer.borderColor = UIColor.red.cgColor
        }
        
        NotificationCenter.default.post(
            name: NSNotification.Name("model updated"),
            object: self,
            userInfo: ["model": model!]
        )
    }
    
    private func setupUI() {
        
//        messageTextView.layer.borderWidth = 0.5
//        messageTextView.layer.cornerRadius = 6
//        messageTextView.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        messageTextView.isScrollEnabled = false
        messageTextView.backgroundColor = .white
        messageTextView.clipsToBounds = true
        
        addCustomToolBar(for: messageTextView)
        
        if model.didSend {
            sendButton.setTitle("Закрыть", for: .normal)
        }
        
        conditionLabel.alpha = model.didSend ? 0.5 : 1
    }
    
    private func setPlaceholder() {
        if messageTextView.text.isEmpty {
            messageTextView.text = "Введите сообщение"
            messageTextView.textColor = .lightGray
        }
    }
    
    private func addCustomToolBar(for textView: UITextView) {
        
        let customToolBar = UIToolbar()
        let doneButton = UIBarButtonItem(title: "Ввод", style: .plain, target: self, action: #selector(doneButtonPressed))
        let flexibleSpace = UIBarButtonItem.flexibleSpace()
        customToolBar.setItems([flexibleSpace, doneButton], animated: false)
        customToolBar.sizeToFit()
        textView.inputAccessoryView = customToolBar
    }
    
    @objc private func doneButtonPressed() {
        view.endEditing(true)
    }
}

// MARK: UITextViewDelegate
extension ExpandedViewController {
        
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if textView.textColor == .lightGray {
            messageTextView.text = nil
            messageTextView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        model.message = textView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        updateUI()
    }
}

// MARK: PAGE Delegates
extension ExpandedViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        pagesViewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        currentViewControllerIndex
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        if var index = pagesViewControllers.firstIndex(where: {$0 == viewController}), index != 0 {
            
            currentViewControllerIndex = index
            
//            if index == 0 {
//                return nil
//            }
            
            index -= 1
            return pagesViewControllers[index]
            
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        if var index = pagesViewControllers.firstIndex(where: {$0 == viewController}),
           index != (pagesViewControllers.count - 1) {
            
            currentViewControllerIndex = index
            
            //            if index == (pagesViewControllers.count - 1) {
            //                return nil
            //            }
            
            index += 1
            return pagesViewControllers[index]
        }
        return nil
    }
}
