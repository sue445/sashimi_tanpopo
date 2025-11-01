# frozen_string_literal: true

RSpec.describe SashimiTanpopo::Logger do
  describe ".info" do
    subject do
      SashimiTanpopo.logger.info(message)
      log_output.string
    end

    include_context :stub_logger

    context "normal" do
      let(:message) { "test" }

      it { should eq " INFO : test\n" }
    end

    context "End with newline" do
      let(:message) { "test\n" }

      it { should eq " INFO : test\n" }
    end

    context "Start with spaces" do
      let(:message) { "  test\n" }

      it { should eq " INFO :   test\n" }
    end
  end
end
