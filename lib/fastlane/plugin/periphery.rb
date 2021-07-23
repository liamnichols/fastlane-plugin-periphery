require 'fastlane/plugin/periphery/version'

module Fastlane
  module Periphery
    def self.all_classes
      Dir[File.expand_path('**/actions/*.rb', File.dirname(__FILE__))]
    end
  end
end

Fastlane::Periphery.all_classes.each do |current|
  require current
end
