import UIKit
import Foundation
import AVFoundation

@available(iOS 8.0, *)
@objc(ContinuousTakePictures) class ContinuousTakePicturesPlugin : CDVPlugin {
    var scanCommand:CDVInvokedUrlCommand?
    
    @objc(ContinuousTakePictures:)
    func scan(_ command: CDVInvokedUrlCommand) {
        
        
        scanCommand=command;

        let vc = ViewController()
        vc.successCallBack = successCallBack
        vc.cancelCallBack = cancelCallBack
        vc.childDir = command.arguments[0] as? String
        self.viewController?.present(vc, animated: false,completion: nil)

    }
    
    func successCallBack(_ imagePath:String?) -> Void {
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: imagePath)
        pluginResult?.setKeepCallbackAs(true)
        commandDelegate.send(pluginResult, callbackId:scanCommand!.callbackId)
    }
    
    func cancelCallBack() -> Void {
		self.viewController?.dismiss(animated:false, completion: nil)
    }
}
