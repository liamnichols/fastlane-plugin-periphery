describe Fastlane::Actions::PeripheryAction do
  describe '#run' do
    it 'raises an error if the version command fails' do
      expect(Fastlane::Actions).to receive(:sh_control_output).with(["periphery", "version"], print_command_output: false).and_raise

      expect do
        Fastlane::Actions::PeripheryAction.run({})
      end.to raise_error("Unable to invoke periphery executable 'periphery'. Is it installed?")
    end

    describe 'with a verified executable' do
      let(:executable) { "mint run peripheryapp/periphery@2.7.1" }
      let(:json) do
        <<-"JSON"
          [
            {
              "ids" : [
                "s:4Core15ISOCallingCodes33_E0B3CC54C1A8D48FB11005B7B77E5818LLV11callingCode010forCountryO0SSSgSS_tFZ"
              ],
              "kind" : "function.method.static",
              "hints" : [
                "redundantPublicAccessibility"
              ],
              "modifiers" : [
                "static",
                "public"
              ],
              "attributes" : [

              ],
              "accessibility" : "public",
              "location" : "\/Code\/Project\/Frameworks\/Core\/Main\/Concepts\/ISO3166Country.swift:287:24",
              "name" : "callingCode(forCountryCode:)"
            },
            {
              "ids" : [
                "s:4Core12LocalizationV22supportedLocalizationsSayACGvpZ"
              ],
              "kind" : "var.static",
              "name" : "supportedLocalizations",
              "attributes" : [

              ],
              "accessibility" : "public",
              "hints" : [
                "unused"
              ],
              "location" : "\/Code\/Project\/Frameworks\/Core\/Main\/Concepts\/Localization.swift:100:23",
              "modifiers" : [
                "public",
                "static"
              ]
            }
          ]
        JSON
      end

      before do
        # Always expect that a version is returned
        expect(Fastlane::Actions).to receive(:sh_control_output)
          .with([executable, "version"], print_command_output: false)
          .once
          .and_return("2.7.1\n")
      end

      it 'can process results json' do
        # Expect the command to return json results
        expect(Fastlane::Actions).to receive(:sh_control_output)
          .with([executable, 'scan', '--disable-update-check', '--format', 'json'], anything)
          .and_return(json)

        result = Fastlane::Actions::PeripheryAction.run({
          executable: executable
        })

        expect(result.map(&:kind)).to eq(["function.method.static", "var.static"])
        expect(result).to equal(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::PERIPHERY_RESULTS])
      end

      it 'sets --skip-build when index_store_path is specified' do
        # Expect the command to be invoked with the --skip-build and correct --index-store-path arguments
        expect(Fastlane::Actions).to receive(:sh_control_output)
          .with([executable, 'scan', '--disable-update-check', '--format', 'json', '--skip-build', '--index-store-path', '/foo/bar'], anything)
          .and_return("[]")

        # Expect index_store_path to exist
        expect(File).to receive(:exist?).with('/foo/bar').and_return(true)

        Fastlane::Actions::PeripheryAction.run({
          executable: executable,
          index_store_path: '/foo/bar'
        })
      end

      it 'finds --index-store-path using derived data from SCAN_DERIVED_DATA_PATH' do
        # Expect the command to be invoked with the --skip-build and correct --index-store-path arguments
        expect(Fastlane::Actions).to receive(:sh_control_output)
          .with([executable, 'scan', '--disable-update-check', '--format', 'json', '--skip-build', '--index-store-path', '/foo/bar/derivedData/Index/DataStore'], anything)
          .and_return("[]")

        # Expect the derived data path to exist
        expect(File).to receive(:exist?).with('/foo/bar/derivedData/').and_return(true)

        Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::SCAN_DERIVED_DATA_PATH] = '/foo/bar/derivedData/'
        Fastlane::Actions::PeripheryAction.run({
          executable: executable,
          skip_build: true
        })
      end

      it 'finds --index-store-path using derived data from XCODEBUILD_DERIVED_DATA_PATH' do
        # Expect the command to be invoked with the --skip-build and correct --index-store-path arguments
        expect(Fastlane::Actions).to receive(:sh_control_output)
          .with([executable, 'scan', '--disable-update-check', '--format', 'json', '--skip-build', '--index-store-path', '/foo/bar/derivedData/Index/DataStore'], anything)
          .and_return("[]")

        # Expect the derived data path to exist
        expect(File).to receive(:exist?).with('/foo/bar/derivedData/').and_return(true)

        Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::XCODEBUILD_DERIVED_DATA_PATH] = '/foo/bar'
        Fastlane::Actions::PeripheryAction.run({
          executable: executable,
          skip_build: true
        })
      end

      it 'prioritises index_store_path when derrived data exists in lane_context' do
        # Expect the command to be invoked with the --skip-build and correct --index-store-path arguments
        expect(Fastlane::Actions).to receive(:sh_control_output)
          .with([executable, 'scan', '--disable-update-check', '--format', 'json', '--skip-build', '--index-store-path', '/path/to/index_store'], anything)
          .and_return("[]")

        # Expect the index store directory to exist
        expect(File).to receive(:exist?).with('/path/to/index_store').and_return(true)

        Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::SCAN_DERIVED_DATA_PATH] = '/foo/bar/derivedData/'
        Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::XCODEBUILD_DERIVED_DATA_PATH] = '/foo/bar'

        Fastlane::Actions::PeripheryAction.run({
          executable: executable,
          skip_build: true,
          index_store_path: '/path/to/index_store'
        })
      end

      it 'supports a custom config file location' do
        # Expect the command to raise an error
        expect(Fastlane::Actions).to receive(:sh_control_output)
          .with([executable, 'scan', '--disable-update-check', '--format', 'json', '--config', '/path/to/periphery.yml'], anything)
          .and_return("[]")

        # Expect that the config file exists
        expect(File).to receive(:exist?).with('/path/to/periphery.yml').and_return(true)

        Fastlane::Actions::PeripheryAction.run({
          executable: executable,
          config: '/path/to/periphery.yml'
        })
      end
    end
  end
end
