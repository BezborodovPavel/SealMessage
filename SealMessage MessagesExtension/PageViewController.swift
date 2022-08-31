//
//  PageViewController.swift
//  SealMessage MessagesExtension
//
//  Created by Павел on 30.08.2022.
//

import UIKit

class PageViewController: UIPageViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pageControl = UIPageControl.appearance()

        pageControl.pageIndicatorTintColor = .gray
        pageControl.currentPageIndicatorTintColor = .black
        
        // Do any additional setup after loading the view.
    }
}
