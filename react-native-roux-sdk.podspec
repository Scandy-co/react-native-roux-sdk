require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-roux-sdk"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "9.0" }
  s.source       = { :git => "https://github.com/Scandy-co/react-native-roux-sdk.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm}"

  s.xcconfig       = { 'FRAMEWORK_SEARCH_PATHS' => '"$(PODS_ROOT)/../Frameworks"', 'HEADER_SEARCH_PATHS' => '"$(PODS_ROOT)/../Frameworks/ScandyCore.framework/Headers/include"' }

  s.dependency "React"
end
