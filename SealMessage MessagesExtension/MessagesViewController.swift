//
//  MessagesViewController.swift
//  SealMessage MessagesExtension
//
//  Created by Павел on 27.08.2022.
//

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController, UITextViewDelegate {
    
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    
    private var isOversized = false {
        didSet{
            guard oldValue != isOversized else {
                return
            }
            messageTextView.setNeedsUpdateConstraints()
            messageTextView.isScrollEnabled = isOversized
            heightConstraint.isActive = isOversized
        }
    }
    private let maxHeight: CGFloat = 100
    
    private var model =  ModelSealMessage() {
        didSet {
            updateUI()
        }
    }
    
    private var conversation: MSConversation? {
        didSet {
            if let conversation = conversation {
                model = getModelMesage(from: conversation) ?? ModelSealMessage()
            }
        }
    }
    
    private var currentViewControllerIndex = 0
    private var pagesViewControllers: [UIViewController]!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPageViewController()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateNotification(withNotification:)),
            name: NSNotification.Name(rawValue: "main view need updated"),
            object: nil)
    }
    
    // MARK: - Conversation Handling
    override func willBecomeActive(with conversation: MSConversation) {
        self.conversation = conversation
    }
    
    override func didResignActive(with conversation: MSConversation) {
        self.conversation = nil
    }
   
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
    
        // Use this method to prepare for the change in presentation style.
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
//        guard let activeView = activeFieldAfterExpanded else {return}
//        activeView.becomeFirstResponder()
//        activeFieldAfterExpanded = nil
        // Called after the extension transitions to a new presentation style.
    
        // Use this method to finalize any behaviors associated with the change in presentation style.
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super .touchesBegan(touches, with: event)
        
        if presentationStyle == .compact {
            requestPresentationStyle(.expanded)
        }
        
        view.endEditing(true)
    }
    
    @IBAction func sendButtonPress() {
        
        guard let msMessage = composeMessage(with: model) else {return}
        guard let conversation = activeConversation else {fatalError("Нет активного диалога!")}
        conversation.insert(msMessage) { error in
            if let error = error {
                fatalError(error.localizedDescription)                
            }
        }
        dismiss()
    }
}

//MARK: Logic
extension MessagesViewController {
    
    private func getModelMesage(from conversation: MSConversation) -> ModelSealMessage? {
    
        guard let msMessage = conversation.selectedMessage else {return nil}
        
        guard let url = msMessage.url else {return nil}
        
        guard let urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
                
        guard let queryItems = urlComponents.queryItems else { return nil }
        
        var modelFromMessage = newModel(from: queryItems)
        
        modelFromMessage.didSend = true
        
        return modelFromMessage
    }
    
    private func newModel(from queryItems: [URLQueryItem]) -> ModelSealMessage {
        
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
    
    private func composeMessage(with model: ModelSealMessage, layoutImg: UIImage? = nil, session: MSSession? = nil) -> MSMessage? {
        
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
extension MessagesViewController {
    
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
        
        var thisIsSender = true

        if let conversation = conversation, conversation.selectedMessage != nil {
            
            let localParticipantIdentifier = conversation.localParticipantIdentifier
            thisIsSender = conversation.selectedMessage!.senderParticipantIdentifier == localParticipantIdentifier
            print("local \(localParticipantIdentifier)")
            print("sender \(conversation.selectedMessage!.senderParticipantIdentifier)")
            print(activeConversation)
        }
        messageTextView.isSecureTextEntry = !thisIsSender
        
        if !thisIsSender {
            messageTextView.layer.borderColor = UIColor.red.cgColor
        }
        
        NotificationCenter.default.post(
            name: NSNotification.Name("model updated"),
            object: self,
            userInfo: ["model": model]
        )
    }
    
    private func setupUI() {
        
        heightConstraint.constant = maxHeight
        heightConstraint.isActive = false
        
        messageTextView.layer.borderWidth = 0.5
        messageTextView.layer.cornerRadius = 6
        messageTextView.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        messageTextView.isScrollEnabled = false
        messageTextView.backgroundColor = .white
        messageTextView.clipsToBounds = true
        
        setPlaceholder()
        addCustomToolBar(for: messageTextView)
        conditionLabel.text = ""
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
}


// MARK: UITextViewDelegate
extension MessagesViewController {
    
    func textViewDidChange(_ textView: UITextView) {
        isOversized = textView.contentSize.height > maxHeight
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if textView.textColor == .lightGray {
            messageTextView.text = nil
            messageTextView.textColor = .black
        }
        if presentationStyle == .compact {
            requestPresentationStyle(.expanded)
        }
        
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        model.message = textView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        updateUI()
    }
}

// MARK: PAGE Delegates
extension MessagesViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        pagesViewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        currentViewControllerIndex
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        if var index = pagesViewControllers.firstIndex(where: {$0 == viewController}) {
            
            currentViewControllerIndex = index
            
            if index == 0 {
                return nil
            }
            
            index -= 1
            
            return pagesViewControllers[index]
            
        }
        
        return nil
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        if var index = pagesViewControllers.firstIndex(where: {$0 == viewController}) {
            
            currentViewControllerIndex = index
            
            if index == (pagesViewControllers.count - 1) {
                return nil
            }
            
            index += 1
            
            return pagesViewControllers[index]
            
        }
        
        return nil
    }
}
