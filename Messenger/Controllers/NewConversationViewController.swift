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
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String:String]]()
    private var results = [[String:String]]()
    private var hasFetched = false
    
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
        
        view.addSubview(noResultsLable)
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        searchBar.delegate = self
        view.backgroundColor = .white
        
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.bounds
        
        noResultsLable.frame = CGRect(x: view.width/4,
                                      y: (view.height - 200)/2,
                                      width: view.width/2,
                                      height: 200)
    }
    
    //MARK: - Selectors
    
    @objc private func dismissSelf(){
        dismiss(animated: true, completion: nil)
    }
    
}

//MARK: - Extension: UITableViewDataSource, UITableViewDelegate

extension NewConversationViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        //startConversation
    }
    
    
}

//MARK: - Extenssion: UISearchBarDelegate

extension NewConversationViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        results.removeAll()
        
        self.spinner.show(in: view)
        
        self.searchUsers(query: text)
    }
    
    func searchUsers(query: String){
        //check if array has firebase reults
        if hasFetched {
            //if it does: filter
            filterUsers(with: query)
        } else {
            //if not, fetch then filter
            DatabaseManager.shared.getAllUsers { [weak self] (result) in
                switch result {
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.users = usersCollection
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }

    }
    
    func filterUsers(with term:String) {
        // update the ui: either show result or show no results label
        guard hasFetched else {
            return
        }
        
        self.spinner.dismiss()
        
        let results: [[String:String]] = self.users.filter({
            guard let name = $0["name"] else {
                return false
            }
            
            return name.hasPrefix(term.lowercased())
        })
        
        self.results = results
        
        self.updateUI()
    }
    
    func updateUI() {
        if results.isEmpty {
            self.noResultsLable.isHidden = false
            self.tableView.isHidden = true
        } else {
            self.noResultsLable.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
    
}
