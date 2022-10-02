//
//  ExpandedViewController.swift
//  SealMessage MessagesExtension
//
//  Created by Павел on 02.09.2022.
//

import UIKit
import CoreLocation
import MessageUI

class ExpandedViewController: UIViewController, UITextViewDelegate, CLLocationManagerDelegate {

    var delegate: MessagesViewControllerDelegate?
    var model: ModelSealMessage!
    let modelLocation = ModelLocation()

    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    
    private var currentViewControllerIndex = 0
    private var pagesViewControllers: [UIViewController]!
    private var locationManager: CLLocationManager!
    private var coverImageView = UIImageView()
    private var modelReceivdedOpened = false
    private var needSend: Bool {
        (model.didSend && !model.senderIsLocal && model.open) || !model.didSend
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if model.open {
            modelReceivdedOpened = true
        }
        
        prepareUI()
        
        DispatchQueue.main.async {
            self.locationManager = CLLocationManager()
            self.locationManager.delegate = self
            self.checkLocationEnable()
        }

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
        delegate?.sendMessage(from: self, needSend: needSend)
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
           self.updateUI()
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
    
    private func addTimer() {
        guard let timerDate = model.openDate else {return}
        let timer = Timer.init(fire: timerDate, interval: 1, repeats: false) { _ in
            self.updateCoverImage()
        }
        
        RunLoop.current.add(timer, forMode: .default)
    }
    
    private func animatePages() {
        guard let firstView = self.pagesViewControllers[0].view else {return}
        guard let secondView = self.pagesViewControllers[1].view else {return}
        firstView.addSubview(secondView)
        secondView.frame = firstView.bounds
        secondView.center.y = firstView.center.y
        secondView.center.x = firstView.center.x + firstView.frame.width
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveLinear]) {
            firstView.center.x -= 15
            secondView.center.x -= 15
        } completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseOut]) {
                firstView.center.x += 15
                secondView.center.x += 15
            } completion: { _ in
                secondView.removeFromSuperview()
            }
        }
    }
}

// MARK: UI
extension ExpandedViewController {
    
    private func prepareUI() {
        setupUI()
        updateUI()
        setupPageViewController()
    }
    
    private func updateUI() {
        
        messageTextView.text = model.message
        
        sendButton.isEnabled = !messageTextView.text.isEmpty
        if model.didSend, !model.senderIsLocal, model.open, !modelReceivdedOpened {
            sendButton.setTitle("Сохранить", for: .normal)
        } else if model.didSend {
            sendButton.setTitle("Закрыть", for: .normal)
        }
        
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
        messageTextView.layer.borderColor = UIColor(displayP3Red: 0.998, green: 0.737, blue: 0.342, alpha: 1).cgColor
        messageTextView.layer.borderWidth = 1
        
        updateCoverImage()

        addCustomToolBar(for: messageTextView)
        
        conditionLabel.alpha = model.didSend ? 0.5 : 1
        
        if !textMustBeVisible(), model.openDate != nil, !conditionExecute() {
            addTimer()
        }
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
        
        if !model.location.isEmpty() {
            if let currentLocation = modelLocation.currentLocation {
                let targetLocation = CLLocation(
                    latitude: model.location.latitude,
                    longitude: model.location.longitude
                )
                
                let currentLocation = CLLocation(
                    latitude: currentLocation.latitude,
                    longitude: currentLocation.longitude)
                
                let distance = targetLocation.distance(from: currentLocation)
                
                if distance >= 50 {return false}
            } else {
                return false
            }
        }
        
        return true
    }
    
    private func textMustBeVisible() -> Bool {
        return model.senderIsLocal || model.open
    }
    
    private func updateCoverImage() {
      
        coverImageView.removeFromSuperview()
        
        if !textMustBeVisible() {
            
        let lock = !conditionExecute()
        
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

        coverImageView = img
        }
    }
}

// MARK: MFMessgaeComposeDelegate

extension ExpandedViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true) {
            if result == .sent {
                self.model = ModelSealMessage()
                self.prepareUI()
            }
        }
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
        
        if let mapViewController = storyboard?.instantiateViewController(withIdentifier: String(describing: MapViewController.self)) as? childrenMapMessageVC {
            controllers.append(mapViewController)
            mapViewController.model = model
            mapViewController.modelLocation = modelLocation
        }
        
        pagesViewControllers =  controllers
    }

    
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

// MARK: Core Location
extension ExpandedViewController {
    
    private func showAlert(with title: String) {
        
        let alert = UIAlertController(title: title, message: "Вы можете изменить разрешение в настройках", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion:nil)
    }
    
    private func checkLocationEnable() {
        if CLLocationManager.locationServicesEnabled(), CLLocationManager.significantLocationChangeMonitoringAvailable() {
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            modelLocation.enabled = true
        } else {
            showAlert(with: "Служба геолокации недоступна")
            modelLocation.enabled = false
        }
    }
     
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last?.coordinate {
            if modelLocation.currentLocation == nil {
                modelLocation.currentLocation = location
                updateCoverImage()
            }
        }
        locationManager.stopUpdatingLocation()
        
        let timer = Timer.init(timeInterval: 5, repeats: false) { _ in
            self.animatePages()
        }
        RunLoop.current.add(timer, forMode: .default)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        case .restricted:
            break
        case .denied:
            self.showAlert(with: "Вы запретили использование местоположения!")
        case .authorizedAlways:
            self.locationManager.startUpdatingLocation()
        case .authorizedWhenInUse:
            self.locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
}
