//
//  ViewController.swift
//  Messenger
//
//  Created by MCT on 9.07.2020.
//  Copyright © 2020 MCT. All rights reserved.
//

import UIKit

class ConversationsViewController: UIViewController {

    
    //MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func viewDidAppear(_ animated: Bool) {
           super.viewDidAppear(animated)
           
           let isLoggedIn = UserDefaults.standard.bool(forKey: "logged_in")
           
           if !isLoggedIn {
               let vc = LoginViewController()
               let nav = UINavigationController(rootViewController: vc)
               nav.modalPresentationStyle = .fullScreen
               
               present(nav, animated: false)
           }
       }
}

