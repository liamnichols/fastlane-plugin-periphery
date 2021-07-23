require 'fastlane/action'
require_relative '../helper/periphery_helper'

module Fastlane
  module Actions
    class PeripheryAction < Action
      def self.run(params)
        UI.message("The periphery plugin is working!")
      end

      def self.description
        "Identifies unused code in Swift projects using Periphery"
      end

      def self.authors
        ["Liam Nichols"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        ""
      end

      def self.available_options
        [
          # FastlaneCore::ConfigItem.new(key: :your_option,
          #                         env_name: "PERIPHERY_YOUR_OPTION",
          #                      description: "A description of your option",
          #                         optional: false,
          #                             type: String)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
