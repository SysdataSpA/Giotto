#
# Be sure to run `pod lib lint Giotto.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Giotto'
  s.version          = '0.3.2'
  s.summary          = 'Theme manager for your app: apply styles to anything you want through a plist file'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
SDThemeManager (henceforth called TM) is born mainly with the intention of simplifying and standardizing development of applications that require the rebranding of the GUI.
The plist describing a theme must contain a Constants dictionary with all constants, while styles can be arranged as desired in other dictionaries. It contains all constants such as font names, colors, or sizes. Technically it is a one level organized dictionary.
At the same level as Constants, other dictionaries can be defined as function groups of graphic styles. Group names are free.
                       DESC

  s.homepage         = 'https://github.com/SysdataSpA/Giotto'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.author           = { 'Sysdata S.p.A.' => 'team.mobile@sysdata.it' }
  s.source           = { :git => 'https://github.com/SysdataSpA/Giotto.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'


  s.subspec 'Core' do |co|
     co.source_files = 'Giotto/Classes/**/*'
  end

  s.subspec 'Blabber' do |bl|
       bl.dependency 'Giotto/Core'
       bl.dependency 'Blabber'
       bl.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'BLABBER=1' }
   end

   s.default_subspec = 'Core'

end
