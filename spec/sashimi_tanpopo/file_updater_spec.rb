# frozen_string_literal: true

RSpec.describe SashimiTanpopo::FileUpdater do
  let(:updater) { SashimiTanpopo::FileUpdater.new(params: params) }

  let(:params) { {} }

  describe "#evaluate" do
    subject { updater.evaluate(body) }

    include_context "within temp dir"

    context "simple case" do
      let(:body) do
        <<~RUBY
          file "test.txt" do |content|
            content.gsub!("name", params[:name])
          end

          file "not_found.txt" do |content|
            content.gsub!("name", params[:name])
          end
        RUBY
      end

      let(:params) { { name: "sue445"} }

      before do
        FileUtils.cp(fixtures_dir.join("test.txt"), ".")
      end

      it "file is updated" do
        subject

        test_txt = File.read("test.txt")
        expect(test_txt).to eq "Hi, sue445\n!"
      end
    end
  end
end
