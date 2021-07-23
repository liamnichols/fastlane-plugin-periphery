describe Fastlane::Actions::PeripheryAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The periphery plugin is working!")

      Fastlane::Actions::PeripheryAction.run(nil)
    end
  end
end
