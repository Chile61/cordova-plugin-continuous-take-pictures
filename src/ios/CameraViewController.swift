//
//  CameraViewController.swift
//  PhotoCollector
//
//  Created by servbus on 2017/5/15.
//  Copyright © 2017年 servbus. All rights reserved.
//

import UIKit


class CameraViewController:UIImagePickerController{
    
	    //禁止旋转，仅支持竖着的。其他的待研究实现方式
    open override var shouldAutorotate:Bool{
        return false
    }
    
    open override var supportedInterfaceOrientations:UIInterfaceOrientationMask{
        return .portrait
    }
}
