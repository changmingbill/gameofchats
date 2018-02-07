//
//  NewMessaageController.swift
//  gameofchats
//
//  Created by 張健民 on 2017/8/6.
//  Copyright © 2017年 CliffC. All rights reserved.
//

import UIKit
import Firebase
class NewMessaageController: UITableViewController {
    
    let cellID = "cellID"
    var users = [User]()
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellID)
        FetchUser()
    }
    
    func FetchUser(){
        //let uid = FIRAuth.auth()?.currentUser?.uid
        FIRDatabase.database().reference().child("users").observe(.childAdded, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: Any]{

                let user = User()
                user.id = snapshot.key //把snapshot key值給id，其餘的給user其他property
//                user.name = dictionary["name"] as! String
//                user.email = dictionary["email"] as! String
                // if you use this setter, your app will crash if your class properties don't exactly match up with the firebase dictionary keys
                user.setValuesForKeys(dictionary)
                self.users.append(user)
                
                //this will crash because of background thread, so lets use dispath_async to fix
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            }
//            print(snapshot)
        })
    }
    
    func handleCancel(){
        dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // let use a hack for now.
        //let cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellID)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! UserCell
        let user = users[indexPath.row]
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email

        
        if let profileImageUrl = user.profileImageUrl {
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    var messagesController: MessagesController?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
       dismiss(animated: true) { 
            print("Dissmiss completed")
            let user = self.users[indexPath.row]
            self.messagesController?.showChatControllerForUser(user: user) //用按壓取值的方式將user data傳給messagesController中的showChatControllerForUser(user: user)方法
        }
    }



}
