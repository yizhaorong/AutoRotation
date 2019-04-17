

Pod::Spec.new do |spec|
  spec.name         = "AutoRotation"
  spec.version      = "0.0.1"
  spec.summary      = "AutoRotation"

  spec.homepage     = "https://github.com/yizhaorong/AutoRotation"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "昭荣伊" => "243653385@qq.com" }
  spec.platform     = :ios, "8.0"
  spec.source       = { :git => "https://github.com/yizhaorong/AutoRotation.git", :tag => "#{spec.version}" }
  spec.source_files  = "AutoRotation/*.{h,m}"
  spec.public_header_files = "AutoRotation/*.h"
end
