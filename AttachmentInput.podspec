Pod::Spec.new do |s|
  s.name         = "AttachmentInput"
  s.version      = "0.0.1"
  s.swift_version = "4.2.0"
  s.ios.deployment_target = "10.0"
  s.license      = "MIT"
  s.summary      = "AttachmentInput is a photo attachment keyboard."
  s.description  = "You can easily select photos, compress photos and videos, launch UIImagePickerController, and take pictures on the keyboard."
  s.homepage     = "https://github.com/cybozu/AttachmentInput.git"
  s.screenshots  = "https://github.com/cybozu/raw/AttachmentInput/master/AttachmentInput.gif"
  s.author       = { "daiki-m" => "daikimat.ai@gmail.com" }
  s.source       = { :git => "https://github.com/cybozu/AttachmentInput.git", :tag => s.version }
  s.source_files = "AttachmentInput/**/*.{generated.swift,swift}"
  s.resources    = "AttachmentInput/**/*.{xib,xcassets,strings}"
  s.dependency "RxSwift"
  s.dependency "RxCocoa"
  s.dependency "RxDataSources"
end