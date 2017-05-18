//
//  ViewController.swift
//  PhotoCollector
//
//  Created by servbus on 2017/5/11.
//  Copyright © 2017年 servbus. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation
import Photos
import AssetsLibrary


class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    let picVc = CameraViewController()
    let btnThumbnail =  UIButton()
    
    let btnFlashMode = UIButton()
    
    open var successCallBack:((String?) -> Void)?
    open var cancelCallBack:(() -> Void)?
    open var childDir:String?
    
    //禁止旋转，仅支持竖着的。其他的待研究实现方式
    open override var shouldAutorotate:Bool{
        return false
    }
    
    open override var supportedInterfaceOrientations:UIInterfaceOrientationMask{
        return .portrait
    }
    
    
    func isGetCameraPermission()->Bool
    {
        let authStaus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo);
        if authStaus != AVAuthorizationStatus.denied
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        //取消
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let img=info[UIImagePickerControllerOriginalImage] as! UIImage
        
        let timage = img.crop(CGSize(width: 200, height: 200))
        btnThumbnail.setImage(timage, for: UIControlState.normal)
        
        
        let tmpPath =  NSHomeDirectory()+"/Documents/"+childDir!+"/"+String(Int(Date().timeIntervalSince1970*1000))
        
        let imagePath = tmpPath+".jpg"
        
        try? UIImageJPEGRepresentation(img, 0.7)?.write(to: URL(fileURLWithPath: imagePath))
        try? UIImageJPEGRepresentation(timage, 0.7)?.write(to: URL(fileURLWithPath: tmpPath+"_t.jpg"))
        
        successCallBack?(imagePath)
        
    }
    func btnCancelAction(_ sender:Any){
        picVc.dismiss(animated: false)
        cancelCallBack?()
    }
    
    func btnTakePicAction(_ sender:Any){
        picVc.takePicture();
    }
    
    func btnFlashModeAction(_ sender:Any){
        switch picVc.cameraFlashMode {
        case .auto:
            picVc.cameraFlashMode = .on
            btnFlashMode.setImage(UIImage(named: "Camera.bundle/btn_camera_flash_on"), for: .normal)
        case .on:
            picVc.cameraFlashMode = .off
            btnFlashMode.setImage(UIImage(named: "Camera.bundle/btn_camera_flash_off"), for: .normal)
        case .off:
            picVc.cameraFlashMode = .auto
            btnFlashMode.setImage(UIImage(named: "Camera.bundle/btn_camera_flash_auto"), for: .normal)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if picVc.isBeingDismissed == true {
            return
        }
        
        if isGetCameraPermission() == false{
            let cv=UIAlertController(title: "提示", message: "未获得授权使用摄像头，请在设置中打开", preferredStyle: .alert);
            let okAction=UIAlertAction(title: "设置", style: .default, handler: {
                action in
                UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!)
            });
            let cancelAction=UIAlertAction(title: "取消", style: .cancel, handler: nil);
            cv.addAction(okAction);
            cv.addAction(cancelAction);
            self.present(cv, animated: false);
            
            return
        }
        //1.判断照片控制器是否可用 ,不可用返回

        //2.创建照片控制器
        
        //3.设置控制器类型
        picVc.sourceType = .camera
        picVc.mediaTypes = [kUTTypeImage as String]
        //4.设置是否可以管理已经存在的图片或者视频
        picVc.allowsEditing = false
        picVc.showsCameraControls=false;
        
        let btnTakePicture = UIButton()
        
        btnTakePicture.setImage(UIImage(named: "Camera.bundle/btn_camera"), for: .normal)
        
        let yMax = self.view.frame.maxY - self.view.frame.minY
        
        let size = CGSize(width:80, height:80);
        let bottomItemsView = UIView(frame:CGRect( origin:CGPoint(x:0.0, y:yMax-115), size:CGSize(width:self.view.frame.size.width, height:115) ) )
        bottomItemsView.backgroundColor = UIColor.white
        
        
        btnTakePicture.bounds = CGRect(origin:CGPoint(x:0,y:0), size:size)
        btnTakePicture.center = CGPoint(x:bottomItemsView.frame.width/2, y:bottomItemsView.frame.height/2)
        btnTakePicture.addTarget(self, action: #selector(btnTakePicAction), for: UIControlEvents.touchUpInside)
        
        bottomItemsView.addSubview(btnTakePicture)
        
        btnThumbnail.bounds = CGRect(x: 0, y: 0, width: size.width-30, height: size.height-30)
        btnThumbnail.center = CGPoint(x: btnThumbnail.bounds.width/2+10, y: bottomItemsView.frame.height/2)
        btnThumbnail.clipsToBounds=true
        btnThumbnail.layer.cornerRadius = btnThumbnail.bounds.width/2
        btnThumbnail.setImage(UIImage(named: "Camera.bundle/image_default"), for: .normal)
        
        btnThumbnail.addTarget(self, action: #selector(btnCancelAction), for: UIControlEvents.touchUpInside)
        
        bottomItemsView.addSubview(btnThumbnail)
        
        let btnCancel = UIButton()
        btnCancel.setImage(UIImage(named: "Camera.bundle/btn_ok"), for: .normal)
        btnCancel.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        btnCancel.center = CGPoint(x: bottomItemsView.frame.width-btnCancel.bounds.width/2-10, y: bottomItemsView.frame.height/2)
        btnCancel.addTarget(self, action: #selector(btnCancelAction), for: UIControlEvents.touchUpInside)
        
        bottomItemsView.addSubview(btnCancel)
        
        
        
        let cov = UIView(frame:CGRect( origin:CGPoint(x:0.0, y:0), size:CGSize(width:self.view.frame.size.width, height:self.view.frame.size.height) ) )
        
        cov.addSubview(bottomItemsView)
        
        //闪光灯控制
        btnFlashMode.setImage(UIImage(named: "Camera.bundle/btn_camera_flash_auto"), for: .normal)
        
        btnFlashMode.bounds = CGRect(x: 0, y: 0, width: 40, height: 40)
        btnFlashMode.center = CGPoint(x: self.view.frame.width-btnFlashMode.bounds.width/2-20, y: btnFlashMode.bounds.height/2 + 20)
        btnFlashMode.addTarget(self, action: #selector(btnFlashModeAction), for: .touchUpInside)
        
        cov.addSubview(btnFlashMode)
        
        picVc.cameraOverlayView=cov;
        
        //5.设置代理
        picVc.delegate = self
        
        //6.弹出控制器
		present(picVc, animated: false)
    }
}





extension UIImage {
    
    func crop(_ to:CGSize) -> UIImage {
        guard let cgimage = self.cgImage else { return self }
        
        let contextImage: UIImage = UIImage(cgImage: cgimage)
        
        let contextSize: CGSize = contextImage.size
        
        //Set to square
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        let cropAspect: CGFloat = to.width / to.height
        
        var cropWidth: CGFloat = to.width
        var cropHeight: CGFloat = to.height
        
        if to.width > to.height { //Landscape
            cropWidth = contextSize.width
            cropHeight = contextSize.width / cropAspect
            posY = (contextSize.height - cropHeight) / 2
        } else if to.width < to.height { //Portrait
            cropHeight = contextSize.height
            cropWidth = contextSize.height * cropAspect
            posX = (contextSize.width - cropWidth) / 2
        } else { //Square
            if contextSize.width >= contextSize.height { //Square on landscape (or square)
                cropHeight = contextSize.height
                cropWidth = contextSize.height * cropAspect
                posX = (contextSize.width - cropWidth) / 2
            }else{ //Square on portrait
                cropWidth = contextSize.width
                cropHeight = contextSize.width / cropAspect
                posY = (contextSize.height - cropHeight) / 2
            }
        }
        
        let rect: CGRect = CGRect(x:posX, y:posY, width:cropWidth, height:cropHeight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let cropped: UIImage = UIImage(cgImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
        
        UIGraphicsBeginImageContextWithOptions(to, true, self.scale)
        cropped.draw(in: CGRect(x:0, y:0,width:to.width, height:to.height))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resized!
    }
}
