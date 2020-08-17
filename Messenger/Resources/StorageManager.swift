//
//  StorageManager.swift
//  Messenger
//
//  Created by MCT on 16.08.2020.
//  Copyright © 2020 MCT. All rights reserved.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    
    //MARK: - Properties
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    /*
     /image/joe-gmail-com_profile_piture.png
     */
    public typealias UplaodPictureCompletion = (Result<String, Error>)-> Void
    
    //MARK: - Enum
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
    
    
    
    //MARK: - Funcs
    
    /// Uploads picture to firebase storage and returns competion with urk string to donwload
    public func uploadProflePicture(with data: Data,
                                    filename:String,
                                    completion: @escaping UplaodPictureCompletion) {
        
        storage.child("images/\(filename)").putData(data,metadata: nil) { (metadata, error) in
            
            guard error == nil else {
                //failed
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storage.child("images/\(filename)").downloadURL { (url, error) in
                guard let url = url else {
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print(urlString)
                completion(.success(urlString))
            }
        }
    }
    
    ///returns the url of the given path
    public func downloadUrl(for path:String, completion: @escaping(Result<URL, Error>)-> Void) {
        
        let reference = storage.child(path)
        
        reference.downloadURL { (url, error) in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            
            completion(.success(url))
        }
        
    }
    
    
}
