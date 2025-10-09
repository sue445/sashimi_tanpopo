# frozen_string_literal: true

RSpec.describe SashimiTanpopo::FileUpdater do
  let(:updater) { SashimiTanpopo::FileUpdater.new }

  describe "#evaluate" do
    subject do
      updater.evaluate(
        recipe_body: recipe_body,
        recipe_path: recipe_path,
        target_dir:  target_dir,
        params:      params,
        dry_run:     dry_run,
      )
    end

    include_context "uses temp dir"

    let(:recipe_path) { "test.rb" }
    let(:target_dir) { temp_dir }
    let(:params) { {} }
    let(:dry_run) { false }

    context "simple case" do
      let(:recipe_body) do
        <<~RUBY
          update_file "test.txt" do |content|
            content.gsub!("name", params[:name])
          end

          update_file "not_found.txt" do |content|
            raise "should not be called here!"
          end
        RUBY
      end

      let(:params) { { name: "sue445"} }

      before do
        FileUtils.cp(fixtures_dir.join("test.txt"), temp_dir)
      end

      it "file is updated" do
        subject

        test_txt = File.read(temp_dir_path.join("test.txt"))
        expect(test_txt).to eq "Hi, sue445!\n"
      end
    end
  end
end
