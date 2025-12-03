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
        is_update_local: is_update_local,
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

    context "many_lines.txt" do
      include_context :stub_logger

      let(:recipe_body) do
        <<~RUBY
          update_file "many_lines.txt" do |content|
            content.gsub!(/a/, "A")
          end
        RUBY
      end

      let(:is_colored) { false }

      before do
        FileUtils.cp(fixtures_dir.join("many_lines.txt"), temp_dir)
      end

      it { should have_key "many_lines.txt" }

      it "file is updated" do
        subject

        many_lines_txt_path = temp_dir_path.join("many_lines.txt")
        many_lines_txt = File.read(many_lines_txt_path)
        expect(many_lines_txt).to include "AAAAAAAAAA"

        expected_diff = [
          " INFO : Checking #{many_lines_txt_path}",
          " INFO : diff:",
          " INFO :  7777777777",
          " INFO :  8888888888",
          " INFO :  9999999999",
          " INFO : -aaaaaaaaaa",
          " INFO : +AAAAAAAAAA",
          " INFO :  bbbbbbbbbb",
          " INFO :  cccccccccc",
          " INFO :  dddddddddd",
          " INFO : #{many_lines_txt_path} is changed",
          "",
        ].join("\n")

        stdout = log_output.string
        expect(stdout).to eq expected_diff
      end
    end

    context "Call update_file multiple times for a same file" do
      let(:is_update_local) { false }

      let(:recipe_body) do
        <<~RUBY
          update_file "test3.txt" do |content|
            content.gsub!("name", params[:name])
          end

          update_file "test3.txt" do |content|
            content.gsub!("lang", params[:lang])
          end
        RUBY
      end

      let(:params) { { name: "sue445", lang: "ja" } }

      let(:expected) do
        {
          "test3.txt" => {
            before_content: "Name=name\nLanguage=lang\n",
            after_content: "Name=sue445\nLanguage=ja\n",
            mode: "100644",
          },
        }
      end

      before do
        FileUtils.cp(fixtures_dir.join("test3.txt"), temp_dir)
      end

      it { should eq expected }
    end

    context "create new file" do
      let(:recipe_body) do
        <<~RUBY
          update_file "new_file.txt", create: true do |content|
            content.replace("My name is " + params[:name])
          end
        RUBY
      end

      let(:params) { { name: "sue445"} }

      let(:expected) do
        {
          "new_file.txt" => {
            before_content: "",
            after_content: "My name is sue445",
            mode: "100644",
          },
        }
      end

      it { should eq expected }
    end
  end
end
