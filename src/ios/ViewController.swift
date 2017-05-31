//
//  ViewController.swift
//  PhotoCollector
//
//  Created by servbus on 2017/5/22.
//  Copyright © 2017年 servbus. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class CustomLine: UIView{
    override func draw(_ rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()!
        
        context.setLineCap(.round)
        context.setLineWidth(1);  //线宽
        context.setAllowsAntialiasing(true);
        context.setStrokeColor(red: 70.0 / 255.0, green: 241.0 / 255.0, blue: 241.0 / 255.0, alpha: 0.6);  //线的颜色
        context.beginPath();
        
        context.move(to: CGPoint(x: 30, y: 0))   //起点坐标
        context.addLine(to: CGPoint(x: 30, y: self.frame.size.height))   //终点坐标
        
        context.move(to: CGPoint(x: 0, y: 30))   //起点坐标
        context.addLine(to: CGPoint(x: self.frame.size.width, y: 30))   //终点坐标
        
        context.move(to: CGPoint(x: self.frame.size.width - 30, y: 0))   //起点坐标
        context.addLine(to: CGPoint(x: self.frame.size.width - 30, y: self.frame.size.height))   //终点坐标
        
        context.strokePath();
        
    }
}

class ViewController: UIViewController {
    
    let captureSession = AVCaptureSession()
    let stillImageOutput = AVCaptureStillImageOutput()
    var captureDevice:AVCaptureDevice? = nil
    var previewLayer:AVCaptureVideoPreviewLayer? = nil
    let focusView = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
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
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        NotificationCenter.default.addObserver(self, selector: #selector(volumeChanged), name: NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
        let mpv = MPVolumeView(frame: CGRect(x: -20, y: -20, width: 0, height: 0))
        mpv.isHidden = false
        
        self.view.addSubview(mpv)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        
    }
    
    func volumeChanged() -> Void {
        btnTakePicAction("")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        let devices = AVCaptureDevice.devices().filter{ ($0 as AnyObject).hasMediaType(AVMediaTypeVideo) && ($0 as AnyObject).position == AVCaptureDevicePosition.back }
        captureDevice = devices.first as? AVCaptureDevice
        if (captureDevice?.isFlashModeSupported(.auto))!{
            try? captureDevice?.lockForConfiguration()
            captureDevice?.flashMode = .auto
            captureDevice?.unlockForConfiguration()
        }
        
        
        captureSession.addInput(try? AVCaptureDeviceInput(device: captureDevice))
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        captureSession.startRunning()
        stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        if captureSession.canAddOutput(stillImageOutput) {
            captureSession.addOutput(stillImageOutput)
        }
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)!
        let pWidth = view.bounds.size.width;
        let pHeight = pWidth*(4.0/3.0)
        previewLayer?.bounds = CGRect(x: 0, y: 0, width: pWidth, height: pHeight)
        previewLayer?.position = CGPoint(x:(previewLayer?.bounds.midX)!, y:(previewLayer?.bounds.midY)!)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspect
        
        //对焦框
        focusView.layer.borderWidth = 1
        focusView.layer.borderColor = UIColor.green.cgColor
        focusView.backgroundColor = UIColor.clear
        focusView.isHidden = true
        
        let cameraPreview = UIView(frame: CGRect(x:0.0, y:0, width:view.bounds.size.width, height:view.bounds.size.height))
        cameraPreview.layer.addSublayer(previewLayer!)
        cameraPreview.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(touchFocus)))
        
        let line = CustomLine()
        line.frame = (previewLayer?.frame)!
        line.backgroundColor = UIColor.clear
        cameraPreview.addSubview(line)
        
        
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
        
        
        //闪光灯
        btnFlashMode.setImage(UIImage(named: "Camera.bundle/btn_camera_flash_auto"), for: .normal)
        
        btnFlashMode.bounds = CGRect(x: 0, y: 0, width: 40, height: 40)
        btnFlashMode.center = CGPoint(x: self.view.frame.width-btnFlashMode.bounds.width/2-25, y: btnFlashMode.bounds.height/2 + 25)
        btnFlashMode.addTarget(self, action: #selector(btnFlashModeAction), for: .touchUpInside)
        
        
        cameraPreview.addSubview(focusView)
        cameraPreview.addSubview(bottomItemsView)
        cameraPreview.addSubview(btnFlashMode)
        view.addSubview(cameraPreview)
        
        
    }
    
    func touchFocus(sender: UITapGestureRecognizer) {
        
        let point =   sender.location(in: self.view)
        
        let cp =  self.previewLayer?.captureDevicePointOfInterest(for: point)
        if (cp?.x)! > CGFloat(1){
            return
        }
        
        try? self.captureDevice?.lockForConfiguration()
        if (self.captureDevice?.isFocusModeSupported(.autoFocus))!{
            
            self.captureDevice?.focusPointOfInterest = cp!
            self.captureDevice?.focusMode = .autoFocus
        }
        if (self.captureDevice?.isExposureModeSupported(.autoExpose))!{
            self.captureDevice?.exposurePointOfInterest = cp!
            self.captureDevice?.exposureMode = .autoExpose
        }
        self.captureDevice?.unlockForConfiguration()
        focusView.center = point
        focusView.isHidden = false
        
        UIView.animate(withDuration: 0.3, animations: {
            self.focusView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }) { (finished) in
            UIView.animate(withDuration: 0.5, animations: {
                self.focusView.transform = CGAffineTransform(scaleX: 1, y: 1)
            }, completion: { (f) in
                self.focusView.isHidden = true
            })
        }
        
        
        
    }
    
    
    func btnCancelAction(_ sender:Any){
        //返回数据
        cancelCallBack?()
    }
    
    func btnTakePicAction(_ sender:Any){
        
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 	1
        animation.toValue = 0
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        
        self.previewLayer?.add(animation, forKey: nil)
        
        
        let queue = DispatchQueue(label: "com.servbus.takePhoto")
        queue.async {
            if let videoConnection = self.stillImageOutput.connection(withMediaType: AVMediaTypeVideo) {
                self.stillImageOutput.captureStillImageAsynchronously(from: videoConnection) {
                    (imageDataSampleBuffer, error) -> Void in
                    if imageDataSampleBuffer == nil {
                        return
                    }
                    
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    let img=UIImage(data: imageData!)!
                    
                    let timage = img.crop(to: CGSize(width: 200, height: 200))
                    
                    self.btnThumbnail.setImage(timage, for: UIControlState.normal)
                    
                    
                    let tmpPath =  NSHomeDirectory()+"/Documents/"+self.childDir!+"/"+String(Int(Date().timeIntervalSince1970*1000))
                    
                    let imagePath = tmpPath+".jpg"
                    
                    try? UIImageJPEGRepresentation(img, 0.7)?.write(to: URL(fileURLWithPath: imagePath))
                    try? UIImageJPEGRepresentation(timage, 0.7)?.write(to: URL(fileURLWithPath: tmpPath+"_t.jpg"))
                    
                    self.successCallBack?(imagePath)
                }
            }
        }
        
        
        
    }
    
    func btnFlashModeAction(_ sender:Any){
        
        try?  self.captureDevice?.lockForConfiguration()
        switch self.captureDevice!.flashMode {
        case .auto:
            self.captureDevice!.flashMode   = .on
            btnFlashMode.setImage(UIImage(named: "Camera.bundle/btn_camera_flash_on"), for: .normal)
        case .on:
            self.captureDevice!.flashMode = .off
            btnFlashMode.setImage(UIImage(named: "Camera.bundle/btn_camera_flash_off"), for: .normal)
        case .off:
            self.captureDevice!.flashMode  = .auto
            btnFlashMode.setImage(UIImage(named: "Camera.bundle/btn_camera_flash_auto"), for: .normal)
        }
        self.captureDevice?.unlockForConfiguration()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}




extension UIImage {
    
    func crop(to:CGSize) -> UIImage {
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

