# cordova-plugin-continuous-take-pictures

这是一个cordova的插件。

已经做了android、ios的支持。

使用自定义相机用来连续拍摄照片。每次拍摄成功照片都会返回照片的路径，并且生成缩略图。缩略图路径规则，比如照片路径为 /../123.jpg ，缩略图路径为 /../123<b>_t</b>.jpg。返回时也会触发成功事件，但照片路径是空字符串。

