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
        delegate?.sendMessage(from: self, needSend: !model.didSend)
    }
    
    private func getStringCondition() -> String {
        
        var stringCondition = ""
        var conditions = [String]()
    
        if let dateCondition = model.openDate {
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ru_RU")
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            dateFormatter.doesRelativeDateFormatting = true
            let date = dateFormatter.string(from: dateCondition)
            conditions.append(date)
        }
        
        if !model.location.isEmpty() {
            conditions.append("рядом с местом \(model.location.description)")
        }
        
        if !conditions.isEmpty {
            stringCondition = "Открыть " + conditions.joined(separator: ", ")
        }
        
        return stringCondition
    }
    
    @objc private func coverImageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        guard let tappedImage = tapGestureRecognizer.view as? UIImageView else {return}
        
        UIView.animate(withDuration: 0.8, delay: 0) {
            tappedImage.alpha = 0
            self.messageTextView.isSelectable = true
       } completion: { _ in
            self.model.open = true
            tappedImage.removeFromSuperview()
        }
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
        sendButton.isEnabled = !messageTextView.text.isEmpty
        setPlaceholder()
        conditionLabel.text = getStringCondition()

        NotificationCenter.default.post(
            name: NSNotification.Name("model updated"),
            object: self,
            userInfo: ["model": model!]
        )
    }
    
    private func setupUI() {
        
        messageTextView.isEditable = !model.didSend
        messageTextView.isScrollEnabled = false
        messageTextView.backgroundColor = .white
        messageTextView.clipsToBounds = true
        
        if !textIsVisible() {
            messageTextView.superview?.addSubview(coverImage(lock: !conditionExecute()))
        }
        
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
    
    private func conditionExecute() -> Bool {
        
        if let openDate = model.openDate {
            if openDate > Date.now {return false}
        }
            
        return true
    }
    
    private func textIsVisible() -> Bool {
        return model.senderIsLocal || model.open
    }
    
    private func coverImage(lock: Bool) -> UIImageView {
      
        let img = UIImageView()
        img.image = UIImage(named: lock ? "closeMessage" : "openMessage")!
        img.tintColor = lock ? .lightGray : .green
        img.contentMode = .scaleAspectFit
        img.backgroundColor = .white
        img.translatesAutoresizingMaskIntoConstraints = false
        
        messageTextView.superview?.addSubview(img)
        
        NSLayoutConstraint.activate([
            img.centerXAnchor.constraint(equalTo: messageTextView.centerXAnchor),
            img.centerYAnchor.constraint(equalTo: messageTextView.centerYAnchor),
            img.widthAnchor.constraint(equalTo: messageTextView.widthAnchor),
            img.heightAnchor.constraint(equalTo: messageTextView.heightAnchor),
        ])
        
        if !lock {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(coverImageTapped(tapGestureRecognizer:)))
            img.isUserInteractionEnabled = true
            img.addGestureRecognizer(tapGestureRecognizer)
        }

        return img
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
            index -= 1
            return pagesViewControllers[index]
            
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        if var index = pagesViewControllers.firstIndex(where: {$0 == viewController}),
           index != (pagesViewControllers.count - 1) {
            currentViewControllerIndex = index
            index += 1
            return pagesViewControllers[index]
        }
        return nil
    }
}
