require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class PeripheryHelper
      # class methods that you define here become available in your action
      # as `Helper::PeripheryHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the periphery plugin helper!")
      end
    end
  end
end
