#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'mop'
  s.version          = '0.1.1'
  s.summary          = 'finclip miniprogram flutter sdk'
  s.description      = <<-DESC
A finclip miniprogram flutter sdk.
                       DESC
  s.homepage         = 'https://www.finclip.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'finogeeks' => 'contact@finogeeks.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.ios.deployment_target = '9.0'
  s.resources = ['Classes/FinAppletExt/Resource/FinAppletExt.bundle']
  s.vendored_libraries = 'Classes/FinAppletExt/Vendor/fincore/libfincore.a'
  s.vendored_libraries = 'Classes/FinAppletExt/Vendor/Lame/libmp3lame.a'
  s.static_framework = true

  s.dependency 'FinApplet' , '2.41.5'
  # s.dependency 'FinAppletExt' , '2.41.5'
  s.dependency 'FinAppletClipBoard', '2.41.5'
end

