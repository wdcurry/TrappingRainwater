# Uncomment the next line to define a global platform for your project
platform :ios, '11.4'

target 'TrappingRainWater' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
	use_frameworks!
    pod 'Neon'
    pod 'SwifterSwift', '~> 4.6.0'
    pod 'PopupDialog'
    pod 'DefaultsKit'
    pod 'Then'
    pod 'SwiftyPickerPopover'
    #pod 'DOAlertController'
    
end

# Workaround for Cocoapods issue #7606
post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        config.build_settings.delete('CODE_SIGNING_ALLOWED')
        config.build_settings.delete('CODE_SIGNING_REQUIRED')
    end
    
    installer.pods_project.targets.each do |target|
        if ['SwifterSwift'].include? target.name
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = 4.2
            end
        end
    end
    
end
