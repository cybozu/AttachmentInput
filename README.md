📷 AttachmentInput 
===

AttachmentInput is a photo attachment keyboard.It is similar to the keyboard for photo attachment of iOS 11 Messenger.  
<img src="https://github.com/cybozu/AttachmentInput/raw/master/AttachmentInput.gif" width="380px"/>

##  🍱 Supported Features
* Shoot a photo on the keyboard
* Pick image/video on the keyboard
* Pick image/video from UIImagePickerController
* Download and attach image/video stored on iCloud
* Compress image/video
* Get the image/video file name, file size, thumbnail image
* Provides custom features
  * see [AttachmentInputConfig](https://github.com/cybozu/AttachmentInput/blob/master/AttachmentInput/AttachmentInput/AttachmentInputConfiguration.swift)

## ⚓  Requirements
AttachmentInput is written in Swift 5. Compatible with iOS 10.0+

## 🏃 Install
Add this to your CocoaPods Podfile.
```
pod 'AttachmentInput'
```
## 🛠️ Usage
1. Add privacy properties in `info.plist` with a usage description
    * Privacy - Photo Library Usage Description  
    * Privacy - Microphone Usage Description  
    * Privacy - Camera Usage Description  
1. Create AttachmentInput instance
    ``` swift
    let attachmentInput = AttachmentInput()
    ```
1. By returning `AttachmentInput#view` at inputview you can display the keyboard in the class that inherited `UIResponder`
    ``` swift
    override var inputView: UIView? {
        return attachmentInput.view
    }
    ```

1. Define the behavior when receive the photos in `AttachmentInputDelegate` and set it to `AttachmentInput`
    ``` swift
    attachmentInput.delegate = self
    ```
1. If you need to use your config, you can pass the config as you create instance
    ``` swift
    let config = AttachmentInputConfiguration()
    config.videoQuality = .typeLow
    attachmentInput = AttachmentInput(configuration: config)
    ```

## 🖋️ License
MIT
