platform :ios, '8.0'

target 'wComics' do
	pod 'GCDWebServer/WebUploader'
end

post_install do | installer |
 	require 'fileutils'
	FileUtils.cp_r('Pods/Target Support Files/Pods-wComics/Pods-wComics-acknowledgements.plist', 'Resources/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end
