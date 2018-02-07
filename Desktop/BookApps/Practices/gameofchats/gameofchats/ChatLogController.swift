//
//  ChatLogController.swift
//  gameofchats
//
//  Created by 張健民 on 2017/8/11.
//  Copyright © 2017年 CliffC. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation
class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    //user data是從NewMessagesController傳送過來，所以是toId data
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            
            observeMessages()
        }
    }
    
    var messages = [Message]()
    
    func observeMessages(){
        guard let uid = FIRAuth.auth()?.currentUser?.uid, let toId = user?.id else{
            return
        }
        
        let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(uid).child(toId)
        
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            let messageId = snapshot.key
            let messagesRef = FIRDatabase.database().reference().child("messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
                
                guard let dictionary = snapshot.value as? [String: AnyObject] else{
                    return
                }
                
//                let message =
                //potential of crashing if keys don't match
//                message.setValuesForKeys(dictionary)
                
//                print("We fetched a message from Firebase, and we need to decide whether or not to filter it out:", message.text)
                //do we need to attempt filtering anymore?
//                if message.chatPartnerId() == self.user?.id{
                    self.messages.append(Message(dictionary: dictionary))
                
                    DispatchQueue.main.async {
                        self.collectionView?.reloadData()
                        //scroll to the last index
                        let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                        self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                    }

//                }
                
            }, withCancel: nil)
        }, withCancel: nil)
    }
    
    lazy var inputTextField: UITextField = {
    let textField = UITextField()
    textField.placeholder = "Enter message..."
    textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        navigationItem.title = user?.name
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0) //設定collectionView與view間的邊界條件
//        collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)//scroll Indicator是指捲動時的那根bar
        collectionView?.alwaysBounceVertical = true //可以維持collectionView顯示保持回彈狀態
        collectionView?.backgroundColor = UIColor.white // view.backgroundColor = UIColor.white這個沒效果
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        
        collectionView?.keyboardDismissMode = .interactive //托曳collectionView時keyboard會跟著互動

//        setupInputComponents()
        setupKeyboardObservers()
    }
    
    lazy var inputContainerView: UIView = {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = UIColor.white
        
        let uploadImageView = UIImageView()
        uploadImageView.image = UIImage(named: "imageIcon")
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.contentMode = .scaleAspectFill
        containerView.addSubview(uploadImageView)
        
        //x,y,width,height
        uploadImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant:6).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true

        uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUploadTap)))
        uploadImageView.isUserInteractionEnabled = true //加這行UITapGestureRecognizer才會有作用
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(sendButton)
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        //x,y,width,height
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        containerView.addSubview(self.inputTextField)
        //x,y,width,height
        self.inputTextField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 6).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        self.inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separatorLineView)
        //x,y,width,height
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true

        return containerView
    }()
    
    func handleUploadTap(){
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true //加入這行在以下程式碼就要加入info["UIImagePickerControllerEditedImage"] 以及 info["UIImagePickerControllerOriginalImage"]，如是false就只要info["UIImagePickerControllerOriginalImage"]
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? URL{
            print("Here's the file url", videoUrl)
            
            let filename = "someFilename.mov"
            FIRStorage.storage().reference().child(filename).putFile(videoUrl, metadata: nil, completion: { (metadata, error) in
                if error != nil{
                    print("Failed upload of video:", error)
                    return
                }
            })
            return
        }
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage{
            selectedImageFromPicker = editedImage
        }else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage{
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker{
            uploadToFirebaseStroageUsingImage(image: selectedImage)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    private func uploadToFirebaseStroageUsingImage(image: UIImage){
        let imageName = NSUUID().uuidString
        let ref = FIRStorage.storage().reference().child("message_images").child(imageName)
        if let uploadData = UIImageJPEGRepresentation(image, 0.2){
            ref.put(uploadData, metadata: nil, completion: { (metadata, error) in
                if error != nil{
                    print("Failed to upload image:", error)
                    return
                }
                if let imageUrl = metadata?.downloadURL()?.absoluteString{
                    self.sendMessageWithImageUrl(imageUrl: imageUrl, image: image)
                }
                
            })
        }
        
    }
    
    
    override var inputAccessoryView: UIView?{
//        get {
        
            return inputContainerView
//        }
    }
    
    override var canBecomeFirstResponder: Bool{
        return true
    }
    
    func setupKeyboardObservers(){
        //keyboard出現時才會執行
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: .UIKeyboardDidShow, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: .UIKeyboardWillShow, object: nil)
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }
    
    func keyboardDidShow(notifcation: Notification){
        if messages.count > 0{
            let indexPath = IndexPath(item: self.messages.count-1, section: 0)
            self.collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        NotificationCenter.default.removeObserver(self)
    }
    
    func handleKeyboardWillShow(notifcation: Notification){
         // notifcation.userInfo包含所有尺寸資訊，keyboardFrame表keyboard尺寸
        let keyboardFrame = (notifcation.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let keyboardDuration = notifcation.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double
        
        containerViewBottomAnchor?.constant = -keyboardFrame!.height
        UIView.animate(withDuration: keyboardDuration!) {
            self.view.layoutIfNeeded() //如有變動constraint就要用這個method，會將self.view的subview重新配置
        }
    }

    
    func handleKeyboardWillHide(notifcation: Notification){
       
        let keyboardDuration = notifcation.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double
        
        containerViewBottomAnchor?.constant = 0
        UIView.animate(withDuration: keyboardDuration!) {
            self.view.layoutIfNeeded() //如有變動constraint就要用這個method，會將self.view的subview重新配置
        }

    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        
        cell.chatLogController = self
        
        let message = messages[indexPath.item]
        cell.textView.text = message.text
        
        setupCell(cell: cell, message: message)
        
        //let modify the bubbleView's width somehow???
        if let text = message.text{
            //a text message
            cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: text).width + 32
            cell.textView.isHidden = false
        }else if message.imageUrl != nil{
            // fall in here if its an image message
            cell.bubbleWidthAnchor?.constant = 200
            cell.textView.isHidden = true //因為imageView的階層在textView下面所以要隱藏起來
        }
        
        return cell
    }
    
    private func setupCell(cell: ChatMessageCell, message: Message){
        if let profileImageUrl = self.user?.profileImageUrl{
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
                if message.fromId == FIRAuth.auth()?.currentUser?.uid{
            //outgoing blue
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white
            cell.profileImageView.isHidden = true
            //要不怕麻煩的多打這兩行，當資訊量大的時候的有可能會有bug
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
        }else{
            //incoming gray
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
        }
        
        if let messageUrl = message.imageUrl{
            cell.bubbleView.backgroundColor = UIColor.clear //這行要先寫，否則bubbleView的顏色還是會先看到
            cell.messgeImageView.loadImageUsingCacheWithUrlString(urlString: messageUrl)
            cell.messgeImageView.isHidden = false
        }else{
            cell.messgeImageView.isHidden = true
        }
        


    }
    //修正旋轉視角bubbleView會置中的問題
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 80
        
        // get estimated height somehow???
        let message = messages[indexPath.item]
        if let text = message.text{
            height = estimateFrameForText(text: text).height + 20
        }else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue{
            // h1 / w1 = h2 / w2
            // solve for h1
            // h1 = h2 / w2 * w1
            height = CGFloat(imageHeight / imageWidth * 200)
        }
        
        
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
    }
    
    private func estimateFrameForText(text: String) -> CGRect{
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin) //使用union可以同時包含兩個屬性:usesFontLeading,usesLineFragmentOrigin
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    var containerViewBottomAnchor: NSLayoutConstraint?
    
    func handleSend(){
        let properties: [String : Any] = ["text": inputTextField.text!]
        sendMessageWithProperties(properties: properties)
    }
    
    private func sendMessageWithImageUrl(imageUrl: String, image: UIImage){
        let properties: [String : Any] = ["imageUrl": imageUrl, "imageWidth": image.size.width, "imageHeight": image.size.height]
        sendMessageWithProperties(properties: properties)
    }
    
    private func sendMessageWithProperties(properties: [String: Any]){
        
        let ref = FIRDatabase.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        //is it there best thing to include the name inside of the message node
        let toId = user!.id! //user是從NewMessageController丟過來的
        let fromId = FIRAuth.auth()!.currentUser!.uid
        let timestamp = NSNumber(value: NSDate().timeIntervalSince1970)
        var values: [String : Any] = ["toId": toId, "fromId": fromId, "timestamp": timestamp]
        //  append properties dictionary onto values somehow??
        
//        let numberWords = ["one", "two", "three"]
//        for word in numberWords {
//            print(word)
//        }
        // Prints "one"
        // Prints "two"
        // Prints "three"
        
//        numberWords.forEach { word in
//            print(word)
//        }
        // Same as above
        //key $0, value $1,{values[$0] = $1}是一個字典的closure,$0代表第一個引數值，$1代表第二個引數值，forEach是for迴圈的closure，只要properties有新值就持續丟進values字典中
        properties.forEach({values[$0] = $1})
        
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil{
                print(error)
                return
            }
            self.inputTextField.text = nil//用""取代nil也可以
            
            let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(fromId).child(toId)
            
            let messageId = childRef.key //childRef.key是ref用childByAutoId()產生的隨機id
            userMessagesRef.updateChildValues([messageId: 1])
            
            let recipientUserMessagesRef = FIRDatabase.database().reference().child("user-messages").child(toId).child(fromId)
            recipientUserMessagesRef.updateChildValues([messageId: 1])
        }
        

    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
    
    var startingFrame: CGRect?
    var blackBackgroundView: UIView?
    var startingImageView: UIView?
    //my custom zooming logic
    func performZoomInForStaringImageView(startingImageView: UIImageView){
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)//取startingImageView size
        
        self.startingImageView = startingImageView
        self.startingImageView?.isHidden = true
        
        let zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.backgroundColor = UIColor.red
        zoomingImageView.image = startingImageView.image
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        zoomingImageView.isUserInteractionEnabled = true
        if let keyWindow = UIApplication.shared.keyWindow{
            blackBackgroundView = UIView(frame: keyWindow.frame)
            blackBackgroundView?.backgroundColor = UIColor.black
            blackBackgroundView?.alpha = 0 //開始時會看不見
            keyWindow.addSubview(blackBackgroundView!) //這行程式碼在前，所以blackBackgroundView會在zoomingImageView之後呈現
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.blackBackgroundView?.alpha = 1 //從0->1，有動畫漸層效果
                self.inputContainerView.alpha = 0
                //math?
                // h2/w2 = h1/w1
                // h2 = h1 / w1 * w2
                let height = self.startingFrame!.height / self.startingFrame!.width * keyWindow.frame.width
                //keyWindow是整個app的view
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                
                zoomingImageView.center = keyWindow.center

                
            }, completion: { (completed) in
//                zoomOutImageView.removeFromSuperview()
            })


        }
        
    }
    
    func handleZoomOut(tapGesture: UITapGestureRecognizer){
        if let zoomOutImageView = tapGesture.view{
            //need to animate back out to controller
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                zoomOutImageView.layer.cornerRadius = 16
                zoomOutImageView.clipsToBounds = true
                zoomOutImageView.frame = self.startingFrame!
                self.blackBackgroundView?.alpha = 0
                 self.inputContainerView.alpha = 1
            }, completion: { (completed: Bool) in
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
            })
            
        }
    }
}
