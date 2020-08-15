//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by MCT on 9.07.2020.
//  Copyright © 2020 MCT. All rights reserved.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {

    //MARK: - Properties
    
    private let spinner = JGProgressHUD()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for Users..."
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let tableview = UITableView()
        tableview.isHidden = true
        tableview.register(UITableViewCell.self,
                           forCellReuseIdentifier: "cell")
        return tableview
    }()
    
    private let noResultsLable: UILabel = {
        let noResultsLable = UILabel()
        noResultsLable.isHidden = true
        noResultsLable.text = "No Results"
        noResultsLable.textAlignment = .center
        noResultsLable.font = .systemFont(ofSize: 21,
                                          weight: .medium)
        noResultsLable.textColor = .green
        return noResultsLable
    }()
    
    //MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        view.backgroundColor = .white
        
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))
        searchBar.becomeFirstResponder()
    }
    
    //MARK: - Selectors
    
    @objc private func dismissSelf(){
        dismiss(animated: true, completion: nil)
    }

}

//MARK: - Extenssion: UISearchBarDelegate

extension NewConversationViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
    }
    
}
