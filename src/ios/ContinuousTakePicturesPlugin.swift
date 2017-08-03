import UIKit
import Foundation
import AVFoundation

@available(iOS 8.0, *)
@objc(ContinuousTakePictures) class ContinuousTakePicturesPlugin : CDVPlugin {
    var scanCommand:CDVInvokedUrlCommand?
    
    @objc(ContinuousTakePictures:)
    func scan(_ command: CDVInvokedUrlCommand) {
        if isGetCameraPermission() == false{
            let cv=UIAlertController(title: "提示", message: "未获得授权使用摄像头，请在设置中打开", preferredStyle: .alert);
            let okAction=UIAlertAction(title: "设置", style: .default, handler: {
                action in
                UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!)
            });
            let cancelAction=UIAlertAction(title: "取消", style: .cancel, handler: nil);
            cv.addAction(okAction);
            cv.addAction(cancelAction);
            self.viewController?.present(cv, animated: false,completion: nil);
            
            return
        }        
        
        scanCommand=command;

        let vc = ViewController()
        vc.successCallBack = successCallBack
        vc.cancelCallBack = cancelCallBack
        vc.childDir = command.arguments[0] as? String
        let strTpls = command.arguments[1] as? String
        if strTpls?.isEmpty == false {
            let data = strTpls?.data(using: String.Encoding.utf8)
            vc.tpls = try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! [[String:Any]]
        }
        vc.isDrawing = (command.arguments[2] as? Bool) ?? false
        vc.isNeedRecord = (command.arguments[3] as? Bool) ?? false
        
        self.viewController?.present(vc, animated: false,completion: nil)

    }
    
    func successCallBack(_ imagePath:String?) -> Void {
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: imagePath)
        pluginResult?.setKeepCallbackAs(true)
        commandDelegate.send(pluginResult, callbackId:scanCommand!.callbackId)
    }
    
    func cancelCallBack() -> Void {
		let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        commandDelegate.send(pluginResult, callbackId:scanCommand!.callbackId)
		self.viewController?.dismiss(animated:false, completion: nil)
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
}
