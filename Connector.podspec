#
# Be sure to run `pod lib lint Connector' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Connector'
  s.version          = '0.1.0'
  s.summary          = 'The eventCenter and route pod'
  s.description      = "TODO: Add long description of the pod here."
  s.swift_version = '5.0'
  s.homepage         = 'https://github.com/kumatt/Connector'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'kumatt' => 'kumattzhou@gmail.com' }
  s.source           = { :git => 'https://github.com/kumatt/Connector.git', :tag => s.version.to_s }
  s.requires_arc = true
  s.ios.deployment_target = '13.0'
  s.source_files = 'Source/Classes/**/*'

end
