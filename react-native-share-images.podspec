require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = "react-native-share-images"
  s.version      = package['version']
  s.summary      = "React Native API to share multiple images"

  s.authors      = { "mojie" => "steven.zhang@mojie.hk" }
  s.homepage     = "https://github.com/theflaming/react-native-share-images#readme"
  s.license      = "MIT"

  s.source       = { :git => "https://github.com/theflaming/react-native-share-images.git" }
  s.source_files  = "ios/**/*.{h,m}"

  s.platforms               = { :ios => "8.0", :tvos => "9.2" }
  s.dependency   "React"
end