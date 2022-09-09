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

        pageControl.currentPageIndicatorTintColor = UIColor(displayP3Red: 0.998, green: 0.737, blue: 0.342, alpha: 1)
        pageControl.pageIndicatorTintColor = UIColor(displayP3Red: 0.998, green: 0.841, blue: 0.603, alpha: 1)
        
    }
}
