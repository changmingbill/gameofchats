//
//  LoginController+handlers.swift
//  gameofchats
//
//  Created by 張健民 on 2017/8/8.
//  Copyright © 2017年 CliffC. All rights reserved.
//

import UIKit
import Firebase
extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    
    
    func handleRegister(){
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text else{
            print("Form is not valid")
            return
        }
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user:FIRUser?, error) in
            if error != nil{
                print(error)
                return
            }
            guard let uid = user?.uid else{
                return
            }
            
            //successfully authenticated user
            let imageName = NSUUID().uuidString
            let storageRef = FIRStorage.storage().reference().child("profile_images").child("\(imageName).jpg")
            
            if let profileImage = self.profileImageView.image, let uploadData = UIImageJPEGRepresentation(profileImage, 0.1){
            
//            if let uploadData = UIImagePNGRepresentation(self.profileImageView.image!){
                storageRef.put(uploadData, metadata: nil, completion: { (metadata, error) in
                    if error != nil{
                        print(error)
                        return
                    }
                    if let profileImageUrl = metadata?.downloadURL()?.absoluteString{
                    
                    let values = ["name": name, "email": email, "profileImageUrl": profileImageUrl]

                    self.registerUserIntoDatabaseWithUID(uid: uid, values: values)
                    print(metadata)
                    }
                })

            }
            
            
        
        })
    }

    private func registerUserIntoDatabaseWithUID(uid: String, values: [String : Any]){
        //URL已寫入GoogleService-info.plist不需再重複了。
        //let ref = FIRDatabase.database().reference(fromURL: "https://gameofchats-8648a.firebaseio.com/")
        let ref = FIRDatabase.database().reference()
        let usersReference = ref.child("users").child(uid)
        usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil{
                print(err)
                return
            }
            
            
            let user = User()
            user.setValuesForKeys(values)
//            self.messagesController?.fetchUserAndSetupNavBarTitle()
//            self.messagesController?.navigationItem.title = values["name"] as? String
            //this setter potentially crashes if keys don't match
//            self.messagesController?.setupNavBarWithUser(user: user)
            self.dismiss(animated: true, completion: nil)
            print("Save user successfully into Firebase db")
        })
    }
    
    func handleSelectProfileImageView(){
        let picker = UIImagePickerController()
        
        picker.delegate = self
        picker.allowsEditing = true//可編輯照片
        
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage{
            selectedImageFromPicker = editedImage
        }else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage{
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker{
            profileImageView.image = selectedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("Canceled picker")
        dismiss(animated: true, completion: nil)
    }
}
