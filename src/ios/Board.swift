import UIKit

enum DrawingState {
    case began, moved, ended
}

class Board: UIImageView {
    
    var beginPoint: CGPoint!
    var endPoint: CGPoint!
    var lastPoint: CGPoint?
    var rects = [CGRect]()
    
    var color: UIColor = UIColor.black
    
    
    var drawingStateChangedBlock: ((_ state: DrawingState) -> ())?
    
    fileprivate var realImage: UIImage?
    
    var drawingState: DrawingState!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func takeImage() -> UIImage {
        UIGraphicsBeginImageContext(self.bounds.size)
        
        self.backgroundColor?.setFill()
        UIRectFill(self.bounds)
        
        self.image?.draw(in: self.bounds)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    // MARK: - drawing
    
    func drawingImage() {
        
        // hook
        if let drawingStateChangedBlock = self.drawingStateChangedBlock {
            drawingStateChangedBlock(self.drawingState)
        }
        
        UIGraphicsBeginImageContext(self.bounds.size)
        
        let context = UIGraphicsGetCurrentContext()
        
        UIColor.clear.setFill()
        UIRectFill(self.bounds)
        context?.setStrokeColor(self.color.cgColor)
        
        if let realImage = self.realImage {
            realImage.draw(in: self.bounds)
        }
        
        let point = CGPoint(x: min(beginPoint.x, endPoint.x), y: min(beginPoint.y, endPoint.y))
        var size = CGSize(width: abs(endPoint.x - beginPoint.x), height: abs(endPoint.y - beginPoint.y))
        if size.height < 6 {
            size.height = 6
        }
        if size.width < 6 {
            size.width = 6
        }
        let rect = CGRect(origin: point, size: size);
        context?.addRect(rect)
        context?.setFillColor(self.color.cgColor)
        context?.fill(rect)
        
        let previewImage = UIGraphicsGetImageFromCurrentImageContext()
        
        if self.drawingState == .ended  {
            self.realImage = previewImage
        }
        UIGraphicsEndImageContext()
        
        // 用 Ended 事件代替原先的 Began 事件
        if self.drawingState == .ended {
            // self.boardUndoManager.addImage(self.image!)
            rects.append(rect)
        }
        
        self.image = previewImage
        
        lastPoint = endPoint
        
    }
    
    
    func drawImage() {
        UIGraphicsBeginImageContext(self.bounds.size)
        
        let context = UIGraphicsGetCurrentContext()
        UIColor.clear.setFill()
        UIRectFill(self.bounds)
        
        context?.addRects(rects)
        context?.setFillColor(self.color.cgColor)
        context?.fill(rects)
        let previewImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        self.image = previewImage
        self.realImage = previewImage
    }
}
