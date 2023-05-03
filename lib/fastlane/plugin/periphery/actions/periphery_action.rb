require 'fastlane/action'
require 'fastlane_core/helper'

module Fastlane
  module Actions
    module SharedValues
      PERIPHERY_RESULTS = :PERIPHERY_RESULTS
    end

    class PeripheryAction < Action
      # https://github.com/peripheryapp/periphery/blob/master/Sources/Frontend/Formatters/JsonFormatter.swift
      class Result
        attr_reader :kind, :name, :modifiers, :attributes, :accessibility, :ids, :hints, :location

        def initialize(raw)
          @kind = raw['kind']
          @name = raw['name']
          @modifiers = raw['modifiers']
          @attributes = raw['attributes']
          @accessibility = raw['accessibility']
          @ids = raw['ids']
          @hints = raw['hints']
          @location = raw['location']
        end
      end

      # fastlane dumps the 'Lane Context' when an action fails
      # Because the results array can contain thousands of items,
      # we don't want to dump them all in the console.
      # Instead, use a custom array which limits the output
      #
      # https://github.com/liamnichols/fastlane-plugin-periphery/issues/2
      class Results < Array
        def to_s
          return super.to_s if length < 2
          "[#{first.inspect}, ...] (#{length} items)"
        end
      end

      class Runner
        attr_reader :executable, :config, :skip_build, :index_store_path, :results

        def expand_and_verify_path(path)
          return nil if path.nil?

          path = File.expand_path(path)
          UI.user_error!("File or directory does not exist at path '#{path}'") unless File.exist?(path)

          path
        end

        def initialize(params)
          @executable = params[:executable] || 'periphery'
          @config = expand_and_verify_path(params[:config])
          @skip_build = params[:skip_build]
          @index_store_path = expand_and_verify_path(params[:index_store_path])
          @results = nil
        end

        def run
          verify_executable
          perform_scan
          print_summary
          results
        end

        def verify_executable
          version = Actions.sh_control_output([executable, 'version'], print_command_output: false).strip!
          UI.message("Using periphery version #{version}")
        rescue
          UI.user_error!("Unable to invoke periphery executable '#{executable}'. Is it installed?")
        end

        def perform_scan
          # Run the periphery scan command and collect the output
          UI.message("Performing scan. This might take a few moments...")
          output = Actions.sh_control_output(scan_command, print_command_output: false, error_callback: lambda { |result|
            UI.error(result)
            UI.user_error!("The scan could not be completed successfully")
          })

          # Decode the JSON output and assign to the property/lane_context
          @results = Results.new(JSON.parse(output).map { |raw| Result.new(raw) })
          Actions.lane_context[SharedValues::PERIPHERY_RESULTS] = results
        end

        def scan_command
          # Build up the initial part of the command
          command = [
            executable,
            'scan',
            '--disable-update-check',
            '--format',
            'json'
          ]

          # Specify the path to the config if it was provided
          if config
            command << '--config'
            command << config
          end

          # Support --skip-build mode
          if skip_build || !index_store_path.nil?
            command << '--skip-build'
            command << '--index-store-path'
            command << resolve_index_store_path
          end

          # Return the complete array of arguments
          command
        end

        def resolve_index_store_path
          # If it was explicitly specified, return the path to the index store
          return index_store_path unless index_store_path.nil?

          # Alternatively, use the derived data path defined by a prior action
          derived_data_path = find_derived_data_path

          # Fail if we couldn't automatically resolve the path
          if derived_data_path.nil?
            UI.user_error!("The index store path could not be resolved. Either specify it using the index_store_path argument or provide a path to derived data when using build_app or xcodebuild actions.")
          end

          # https://github.com/peripheryapp/periphery#xcode
          if Helper.xcode_at_least?("14.0.0")
            return File.join(derived_data_path, 'Index.noindex', 'DataStore')
          else
            return File.join(derived_data_path, 'Index', 'DataStore')
          end
        end

        def find_derived_data_path
          # These values are set by other actions that may have been used to build an app previously
          candidates = [
            Actions.lane_context[SharedValues::SCAN_DERIVED_DATA_PATH],
            Actions.lane_context[SharedValues::XCODEBUILD_DERIVED_DATA_PATH]
          ]

          # Return the first candidate where the value was set and the directory still exists
          candidates.find { |x| !x.nil? && File.exist?(x) }
        end

        def print_summary
          # Group the results by their first hint (assume there is only one).
          grouped_results = results
                            .group_by { |result| result.hints.first }
                            .transform_values(&:count)

          # Print the counts in a table
          FastlaneCore::PrintTable.print_values(config: grouped_results, title: 'Summary of Results') unless Helper.test?
        end
      end

      def self.run(params)
        require 'json'

        Runner.new(params).run
      end

      def self.description
        "Identifies unused code in Swift projects using Periphery"
      end

      def self.authors
        ["Liam Nichols"]
      end

      def self.return_value
        "Output of the command parsed from JSON into an array of Result objects"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :executable,
                                       env_name: "PERIPHERY_EXECUTABLE",
                                       description: "Path to the `periphery` executable on your machine",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :config,
                                       env_name: "PERIPHERY_CONFIG",
                                       description: "Path to configuration file",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :skip_build,
                                       env_name: "PERIPHERY_SKIP_BUILD",
                                       description: "Skip the project build step",
                                       optional: true,
                                       default_value: false,
                                       type: Boolean),
          FastlaneCore::ConfigItem.new(key: :index_store_path,
                                       env_name: "PERIPHERY_INDEX_STORE_PATH",
                                       description: "Path to index store to use",
                                       optional: true,
                                       type: String)
        ]
      end

      def self.output
        [
          ["PERIPHERY_RESULTS", "The output of periphery decoded into an array of Result objects."]
        ]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
