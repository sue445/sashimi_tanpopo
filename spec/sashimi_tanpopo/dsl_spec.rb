# frozen_string_literal: true

RSpec.describe SashimiTanpopo::DSL do
  let(:dsl) { SashimiTanpopo::DSL.new }

  describe "#evaluate" do
    subject do
      dsl.evaluate(
        recipe_body:     recipe_body,
        recipe_path:     recipe_path,
        target_dir:      target_dir,
        params:          params,
        dry_run:         dry_run,
        is_colored:      is_colored,
        is_update_local: true,
      )
    end

    include_context "uses temp dir"

    let(:recipe_path) { "test.rb" }
    let(:target_dir) { temp_dir }
    let(:params) { {} }
    let(:dry_run) { false }
    let(:is_colored) { true }
    let(:is_update_local) { true }

    context "update single file" do
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

      let(:expected) do
        {
          "test.txt" => {
            before_content: "Hi, name!\n",
            after_content: "Hi, sue445!\n",
            mode: "100644",
          },
        }
      end

      before do
        FileUtils.cp(fixtures_dir.join("test.txt"), temp_dir)
      end

      it { should eq expected }

      it "file is updated" do
        subject

        test_txt = File.read(temp_dir_path.join("test.txt"))
        expect(test_txt).to eq "Hi, sue445!\n"
      end
    end

    context "update multiple files" do
      let(:recipe_body) do
        <<~RUBY
          update_file "*.txt" do |content|
            content.gsub!("name", params[:name])
          end
        RUBY
      end

      let(:params) { { name: "sue445"} }

      let(:expected) do
        {
          "test.txt" => {
            before_content: "Hi, name!\n",
            after_content: "Hi, sue445!\n",
            mode: "100644",
          },
          "test2.txt" => {
            before_content: "Hello, name!\n",
            after_content: "Hello, sue445!\n",
            mode: "100644",
          },
        }
      end

      before do
        FileUtils.cp(fixtures_dir.join("test.txt"), temp_dir)
        FileUtils.cp(fixtures_dir.join("test2.txt"), temp_dir)
      end

      it { should eq expected }

      it "files are updated" do
        subject

        test_txt = File.read(temp_dir_path.join("test.txt"))
        expect(test_txt).to eq "Hi, sue445!\n"

        test_txt2 = File.read(temp_dir_path.join("test2.txt"))
        expect(test_txt2).to eq "Hello, sue445!\n"
      end
    end

    context "empty recipe" do
      let(:recipe_body) do
        <<~RUBY
          update_file "test.txt" do |content|
          end
        RUBY
      end

      before do
        FileUtils.cp(fixtures_dir.join("test.txt"), temp_dir)
      end

      it { should be_empty }

      it "file is not updated" do
        subject

        test_txt = File.read(temp_dir_path.join("test.txt"))
        expect(test_txt).to eq "Hi, name!\n"
      end
    end

    context "dry_run is enabled" do
      let(:dry_run) { true }

      describe "dry_run? is available" do
        let(:recipe_body) do
          <<~RUBY
            raise "should not be called here!" unless dry_run?
          RUBY
        end

        it { should be_empty }
      end
    end
  end
end
