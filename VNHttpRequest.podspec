#
#  Be sure to run `pod spec lint VNHttpRequest.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|



  s.name         = "VNHttpRequest"
  s.version      = "1.0.1"
  s.summary      = "AFNetworking fsdoa"

  s.description  = <<-DESC
  Net request ,call back data Serialization to CH
                   DESC

  s.homepage     = "https://github.com/guohongqi-china/VNHttpRequest"
  s.license      = "MIT"
  s.author             = { "guohongqi-china" => "820003039@qq.com" }
  s.ios.deployment_target = '8.0'


  s.source       = { :git => "https://github.com/guohongqi-china/VNHttpRequest.git", :tag => s.version.to_s }
  s.public_header_files = "VNHttpRequest/VNHttpRequest.h"
  s.source_files  = "VNHttpRequest/VNHttpRequest.h"


  s.dependency "AFNetworking", "~> 3.0"
  s.requires_arc = true

  pch_AF = <<-EOS
#ifndef TARGET_OS_IOS
  #define TARGET_OS_IOS TARGET_OS_IPHONE
#endif

EOS
  s.prefix_header_contents = pch_AF
  s.ios.deployment_target = '8.0'

  s.subspec 'FrameWork' do |ss|
    ss.source_files = 'VNHttpRequest/FrameWork/**/*.{h,m}'
    ss.public_header_files = 'VNHttpRequest/FrameWork/**/*.{h}'
    ss.watchos.frameworks = 'MobileCoreServices', 'CoreGraphics'
    ss.ios.frameworks = 'MobileCoreServices', 'CoreGraphics'
    ss.osx.frameworks = 'CoreServices'
  end

  # spec.resource  = "icon.png"
  # spec.resources = "Resources/*.png"
  # spec.preserve_paths = "FilesToSave", "MoreFilesToSave"
  # spec.framework  = "SomeFramework"
  # spec.frameworks = "SomeFramework", "AnotherFramework"
  # spec.library   = "iconv"
  # spec.libraries = "iconv", "xml2"
  # spec.requires_arc = true
  # spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # spec.dependency "JSONKit", "~> 1.4"

end
