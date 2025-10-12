# frozen_string_literal: true

RSpec.describe SashimiTanpopo::Provider::GitHub do
  let(:provider) do
    SashimiTanpopo::Provider::GitHub.new(
      recipe_paths: recipe_paths,
      target_dir:   target_dir,
      params:       params,
      dry_run:      dry_run,
      is_colored:   is_colored,
    )
  end

  include_context "uses temp dir"

  let(:recipe_paths) { [] }
  let(:target_dir) { temp_dir }
  let(:params) { {} }
  let(:dry_run) { false }
  let(:is_colored) { true }

  describe "#perform" do
    subject { provider.perform }

    before do
      FileUtils.cp(fixtures_dir.join("test.txt"), temp_dir)
    end

    let(:recipe_paths) do
      [
        fixtures_dir.join("recipe.rb").to_s,
      ]
    end

    let(:params) { { name: "sue445"} }

    it "file is updated" do
      subject

      test_txt = File.read(temp_dir_path.join("test.txt"))
      expect(test_txt).to eq "Hi, sue445!\n"
    end
  end
end
