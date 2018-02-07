//
//  ChatMessageCell.swift
//  gameofchats
//
//  Created by 張健民 on 2017/8/16.
//  Copyright © 2017年 CliffC. All rights reserved.
//

import UIKit

class ChatMessageCell: UICollectionViewCell {
    
    var chatLogController: ChatLogController?
    
    let textView: UITextView = {
        let tv = UITextView()
        tv.text = "SAMPLE TEXT FOR NOW"
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = UIColor.clear //要把textView顏色處理掉才能看到bubbleView
        tv.textColor = UIColor.white
        tv.isEditable = false
//        tv.backgroundColor = UIColor.yellow //先著色來觀察顯示的階層在上還是下
        return tv
    }()
    //static只能用ChatMessageCell.blueColor來使用，不能用其他類別名稱，例:cell.blueColor
    static let blueColor = UIColor(r: 0, g: 137, b: 249)
    
    let bubbleView: UIView = {
        let view  = UIView()
        view.backgroundColor = blueColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "gameofthrones")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    lazy var messgeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true //決定使用者事件是否會被忽略以及在事件執行緒中是否會被移除，沒有這行tap無反應
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomTap)))

        return imageView
    }()
    //這個方法主要的目的是要得到messgeImageView，轉換給chatLogController
    func handleZoomTap(tapGesture: UITapGestureRecognizer){
        if let imageView = tapGesture.view as? UIImageView{//imageView表被觸到的imageView
        //PRO Tip: don't perform a lot of custom logic inside of a view class
            self.chatLogController?.performZoomInForStaringImageView(startingImageView: imageView)
        }
    }
    
    var bubbleWidthAnchor: NSLayoutConstraint?
    var bubbleViewRightAnchor: NSLayoutConstraint?
    var bubbleViewLeftAnchor: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(bubbleView)
        addSubview(textView)
        addSubview(profileImageView)
        
        bubbleView.addSubview(messgeImageView)
        //x,y,w,h
        messgeImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
        messgeImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        messgeImageView.widthAnchor.constraint(equalTo: bubbleView.widthAnchor).isActive = true
        messgeImageView.heightAnchor.constraint(equalTo: bubbleView.heightAnchor).isActive = true
        
        //x,y,w,h
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        //x,y,w,h
        bubbleViewRightAnchor = bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8)
        bubbleViewRightAnchor?.isActive = true
        
        bubbleViewLeftAnchor = bubbleView.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8)
//        bubbleViewLeftAnchor?.isActive = false
        
        bubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        
        bubbleWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
        bubbleWidthAnchor?.isActive = true
        bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        //x,y,w,h
//        textView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 8).isActive = true
        textView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
//        textView.widthAnchor.constraint(equalToConstant: 200).isActive = true
         textView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true
        textView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
