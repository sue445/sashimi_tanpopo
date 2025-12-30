# frozen_string_literal: true

RSpec.describe SashimiTanpopo::Provider::Base do
  let(:provider) do
    SashimiTanpopo::Provider::Base.new(
      recipe_paths:    recipe_paths,
      target_dir:      target_dir,
      params:          params,
      dry_run:         dry_run,
      is_colored:      is_colored,
      is_update_local: is_update_local,
    )
  end

  include_context "uses temp dir"

  let(:recipe_paths) { [] }
  let(:target_dir) { temp_dir }
  let(:params) { {} }
  let(:dry_run) { false }
  let(:is_colored) { true }
  let(:is_update_local) { false }

  describe "#apply_recipe_files" do
    subject { provider.apply_recipe_files }

    before do
      FileUtils.cp(fixtures_dir.join("test.txt"), temp_dir)
    end

    let(:params) { { name: "sue445"} }

    context "with single recipe" do
      let(:recipe_paths) do
        [
          fixtures_dir.join("recipe.rb").to_s,
        ]
      end

      let(:expected) do
        {
          "test.txt" => {
            before_content: "Hi, name!\n",
            after_content: "Hi, sue445!\n",
            mode: "100644",
          },
        }
      end

      it { should eq expected }
    end

    context "with multiple recipes" do
      let(:recipe_paths) do
        [
          fixtures_dir.join("recipe.rb").to_s,
          fixtures_dir.join("recipe2.rb").to_s,
        ]
      end

      let(:expected) do
        {
          "test.txt" => {
            before_content: "Hi, name!\n",
            after_content: "Hello, sue445!\n",
            mode: "100644",
          },
        }
      end

      it { should eq expected }
    end
  end
end
