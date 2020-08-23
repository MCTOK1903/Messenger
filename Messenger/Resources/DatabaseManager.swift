//
//  DatabaseManager.swift
//  Messenger
//
//  Created by MCT on 11.07.2020.
//  Copyright © 2020 MCT. All rights reserved.
//

import Foundation
import FirebaseDatabase

//MARK: - struct
struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String {
        //image/joe-gmail-com_profile_piture.png
        return "\(safeEmail)_profile_picture.png"
    }
}

//MARK: - Class
final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(email: String) -> String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}




//MARK: - Extension: Account Management

extension DatabaseManager {
    
    //MARK: - errors enum
    public enum DatabaseError: Error {
        case failedToFetch
    }
    
    //MARK: - funcs
    /// checking user email in firebase
    public func userExist(with email: String,
                          completion: @escaping ((Bool) -> Void)){
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { (snapshot) in
            
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            
            completion(true)
        }
        
    }
    
    /// Insert new user to Firebase
    public func insertUser(with user: ChatAppUser, completion: @escaping(Bool)-> Void){
        
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
            ], withCompletionBlock: { error, _ in
                guard error == nil else {
                    print("failed to write to database")
                    completion(false)
                    return
                }
                
                self.database.child("users").observeSingleEvent(of: .value) { (snapshot) in
                    if var usersCollection = snapshot.value as? [[String:String]] {
                        //append to user dic.
                        let newElement = [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                        usersCollection.append(newElement)
                        
                        self.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                        
                    } else {
                        //create array
                        let newCollection: [[String:String]] = [
                            [
                                "name": user.firstName + " " + user.lastName,
                                "email": user.safeEmail
                            ]
                        ]
                        
                        self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                    }
                }
        })
    }
    /*
     users => [
                [
                    "name":
                    "safeEmail":
                ],
                [
                    "name":
                    "safeEmail":
                ],
             ]
     */
    
    ///get all users from firease
    public func getAllUsers(completion: @escaping(Result<[[String:String]], Error>)-> Void) {
        database.child("users").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [[String:String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            completion(.success(value))
        }
    }
    
}

//MARK: - Sending Messages / Conversations
extension DatabaseManager{
    
    /*
     
     "uniqueId" {
        "message":[
            {
                 "id": String
                 "type": text,photo etc
                 "content": String
                 "date": date()
                 "sender_email": String
                 "isRead": true/false
     
            }
        ]
     
     }
    Conversatuon => [
        [
            "conversationId": "uniqueId",
            "other_user_email":
            "lastest_message": => {
                "date": Date()
                "lastest_message": "message"
                "isRead": true/false
            }
        ]
     
    ]
    */
    
    ///Creates a new conversation with target user email and first nessages sent
    public func createNewConversation(with otherUserEmail:String, firstMessages: Message, completion: @escaping(Bool)-> Void){
        
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(email: currentEmail)
        let ref = database.child("\(safeEmail)")
        
        ref.observeSingleEvent(of: .value) { (snapshot) in
            guard var userNode = snapshot.value as? [String:Any] else {
                completion(false)
                print("User not found")
                return
            }
            
            let messageDate = firstMessages.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessages.kind{
                
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessages.messageId)"
            
            let newConversationData: [String:Any] = [
                "id":conversationId,
                "other_user_email": otherUserEmail,
                "lastest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            if var conversations = userNode["conversations"] as? [[String:Any]] {
                //convo aray exist for current user
                // you should apped
                
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                
                ref.setValue(userNode) { [weak self] (error, _) in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(ConversationID: conversationId,
                                                     firstMessage: firstMessages,
                                                     completion: completion)
                }
                
            } else {
                //convo array does not exist
                //create it
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode) { [weak self] (error, _) in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(ConversationID: conversationId,
                                                     firstMessage: firstMessages,
                                                     completion: completion)
                }
            }
        }
        
    }
    
    private func finishCreatingConversation(ConversationID:String, firstMessage: Message, completion: @escaping(Bool) -> Void ){
//        "message":[
//               {
//                    "id": String
//                    "type": text,photo etc
//                    "content": String
//                    "date": date()
//                    "sender_email": String
//                    "isRead": true/false
//
//               }
//           ]
        
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        
        switch firstMessage.kind{
            
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .custom(_):
            break
        }
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") else {
            completion(false)
            return
        }
        
        let collectionMessage: [String:Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false
        ]
        
        let value: [String:Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        database.child("\(ConversationID)").setValue(value) { (error, _) in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
        
        
    }
    
    
    ///Fetches and results all conversation for the user with passed in email
    public func getAllConversations(for email:String, completion: @escaping (Result<String, Error>)-> Void){
        
    }
    
    /// Get all messages for a given conversations
    public func getAllMessagesForConversation(with id:String, completion: @escaping(Result<String, Error>)->Void){
        
    }
    
    ///Sends a messages wiith target conversation and messages
    public func sendMessage(to conversation: String, message:Message, completion: @escaping(Bool)->Void){
        
    }
    
}


