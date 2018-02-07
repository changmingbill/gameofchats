//
//  ViewController.swift
//  gameofchats
//
//  Created by 張健民 on 2017/8/2.
//  Copyright © 2017年 CliffC. All rights reserved.
//

import UIKit
import Firebase
class MessagesController: UITableViewController {

    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        let image = UIImage(named: "Group 5")
    
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(handleNewMessage))
        checkIfUserIsLoggedIn()
//        observeUserMessages()

        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
//        observeMessages()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        observeUserMessages()
//        checkIfUserIsLoggedIn()
        
        
        
    }

    var messages = [Message]()
    
    var messagesDictionary = [String: Message]()
    
    func observeUserMessages(){
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        let ref = FIRDatabase.database().reference().child("user-messages").child(uid)
        //先用observe取snapshot.key(child("user-messages").child(uid))從NewMessageController那兒製造的.child("user-messages").child(fromId)兩個id做比對，再用一個observe取fromId底下的值
        ref.observe(.childAdded, with: { (snapshot) in
            let userId = snapshot.key
            FIRDatabase.database().reference().child("user-messages").child(uid).child(userId).observe(.childAdded, with: { (snapshot) in
               
            let messageId = snapshot.key
            self.fetchMessageWithMessageId(messageId: messageId)
                
            }, withCancel: nil)
        }, withCancel: nil)
    }
    
    private func fetchMessageWithMessageId(messageId: String){
        let messagesReference = FIRDatabase.database().reference().child("messages").child(messageId)
        
        //只要entire Value，就選.value
        messagesReference.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject]{
                let message = Message(dictionary: dictionary)
//                message.setValuesForKeys(dictionary)
                //self.messages.append(message) //每個snapshot中的dictionary存進message後再存入messages的陣列
                
                if let chatPartnerId = message.chatPartnerId(){
                    self.messagesDictionary[chatPartnerId] = message //以toId當key做分類，將不同的message裝填進這個messagesDictionary中，重覆的toId會被最新的data取代
                }
                
                self.attemptReloadOfTable()
            }
            
        }, withCancel: nil)

    }
    
    var timer: Timer?
    private func attemptReloadOfTable(){
        
        self.timer?.invalidate() //remove the timer from its run loop.
        print("we just canceled our timer")
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
        print("schedule a table reload in 0.1 sec")
    }
    
    
    func handleReloadTable(){
        self.messages = Array(self.messagesDictionary.values)
        
        self.messages.sort(by: { (message1, message2) -> Bool in
            return (message1.timestamp?.intValue)! > (message2.timestamp?.intValue)!
        })

        //this will crash because of background thread, so lets call this on dispatch_async main thread
        DispatchQueue.main.async {
            print("we reloaded the table")
            self.tableView.reloadData()
        }

    }
//    
//    func observeMessages(){
//        let ref = FIRDatabase.database().reference().child("messages")
//        ref.observe(.childAdded, with: { (snapshot) in
//            if let dictionary = snapshot.value as? [String: AnyObject]{
//                let message = Message()
//                message.setValuesForKeys(dictionary)
////                self.messages.append(message) //每個snapshot中的dictionary存進message後再存入messages的陣列
//                
//                if let toId = message.toId{
//                   self.messagesDictionary[toId] = message //以toId當key做分類，將不同的message裝填進這個messagesDictionary中，重覆的toId會被最新的data取代
//                    self.messages = Array(self.messagesDictionary.values)
//                
//                    self.messages.sort(by: { (message1, message2) -> Bool in
//                        return (message1.timestamp?.intValue)! > (message2.timestamp?.intValue)!
//                    })
//                }
//                
//                //this will crash because of background thread, so lets call this on dispatch_async main thread
//                DispatchQueue.main.async {
//                    self.tableView.reloadData()
//                }
//                
//            }
//        })
//    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cellId")
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        let message = messages[indexPath.row] //indexPath.row會將messages這個陣列從0~messages.count排列出來
        cell.message = message //將messages這個陣列裡的(從雲端下載)值裝填進cell.message裡，執行cell.message這個closure後用tableview呈現
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        
        guard let chatPartnerId = message.chatPartnerId() else{
            return
        }
        
        let ref = FIRDatabase.database().reference().child("users").child(chatPartnerId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionary = snapshot.value as? [String: AnyObject] else{
                return
            }
            
            let user = User()
            user.id = chatPartnerId
            user.setValuesForKeys(dictionary)
            self.showChatControllerForUser(user: user)
            
        }, withCancel: nil)
        

    }
    
    func handleNewMessage(){
        let newMessageController = NewMessaageController()
        newMessageController.messagesController = self //newMessageController用到messagesController裡的method，首先要在自己的class生成一個messagesController，然後再到messagesController的class中，委派給messagesController，轉場則不用。
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
        
    }
    func checkIfUserIsLoggedIn(){
        if FIRAuth.auth()?.currentUser?.uid == nil{
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        }else{
            fetchUserAndSetupNavBarTitle()
        }
    }
    
    func fetchUserAndSetupNavBarTitle(){
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else{
            //for some reasons uid = nil
            return
        }
        FIRDatabase.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject]{
                //                self.navigationItem.title = dictionary["name"] as! String
                
                let user = User()
                user.setValuesForKeys(dictionary)
                self.setupNavBarWithUser(user: user)
            }
        }, withCancel: nil)
        
    }
    
    func setupNavBarWithUser(user: User){
        messages.removeAll()
        messagesDictionary.removeAll()
        tableView.reloadData()
        
//        observeUserMessages()
        
//        self.navigationItem.title = user.name
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
//        titleView.backgroundColor = UIColor.red
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(containerView)
        
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        if let profileImageUrl = user.profileImageUrl{
            profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        containerView.addSubview(profileImageView)
        
        //iso 9 constraint anchors
        //need x, y, width, height anchors
        profileImageView.rightAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let nameLabel = UILabel()
        containerView.addSubview(nameLabel)
        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        //iso 9 constraint anchors
        //need x, y, width, height anchors
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        
        
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        
        self.navigationItem.titleView = titleView
        
//        titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showChatController)))
    }
    
    func showChatControllerForUser(user: User){
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user //user data是從NewMessaageController傳來的，再從這兒丟給chatLogController的user
        navigationController?.pushViewController(chatLogController, animated: true)
        
    }
    
    func handleLogout(){ 
        //try? FIRAuth.auth()?.signOut()
        do{
            try FIRAuth.auth()?.signOut()
        }catch let logoutError{
            print(logoutError)
        }
        
        let loginController = LoginController()
        loginController.messagesController = self
        present(loginController, animated: true, completion: nil)
    }

}

