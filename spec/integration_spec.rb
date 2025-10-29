# frozen_string_literal: true

RSpec.describe "sashimi_tanpopo" do
  describe "local" do
    include_context "uses temp dir"

    before do
      FileUtils.cp(fixtures_dir.join("test.txt"), temp_dir)
      FileUtils.cp(fixtures_dir.join("recipe.rb"), temp_dir)
    end

    context "with single --params" do
      it "run command" do
        sh "#{exe_sashimi_tanpopo} local --target-dir=#{temp_dir} --params=name:sue445 #{temp_dir_path.join("recipe.rb")}"

        test_txt = File.read(temp_dir_path.join("test.txt"))
        expect(test_txt).to eq "Hi, sue445!\n"
      end
    end

    context "with multiple --params" do
      before do
        FileUtils.cp(fixtures_dir.join("test3.txt"), temp_dir)
        FileUtils.cp(fixtures_dir.join("recipe_test3.rb"), temp_dir)
      end

      it "run command" do
        sh "#{exe_sashimi_tanpopo} local --target-dir=#{temp_dir} --params=name:sue445 --params=lang:ja #{temp_dir_path.join("recipe_test3.rb")}"

        test_txt = File.read(temp_dir_path.join("test3.txt"))
        expect(test_txt).to eq "Name=sue445\nLanguage=ja\n"
      end
    end

    context "without --params" do
      it "run command" do
        sh "#{exe_sashimi_tanpopo} local --target-dir=#{temp_dir} #{temp_dir_path.join("recipe.rb")}"

        test_txt = File.read(temp_dir_path.join("test.txt"))
        expect(test_txt).to eq "Hi, name!\n"
      end
    end
  end

  describe "github", if: ENV["CI"] do
    include_context "uses temp dir"

    before do
      FileUtils.cp(fixtures_dir.join("test.txt"), temp_dir)
      FileUtils.cp(fixtures_dir.join("recipe.rb"), temp_dir)
    end

    it "run command and output to job summary" do
      sh "#{exe_sashimi_tanpopo} github --target-dir=#{temp_dir} --params=name:sue445 #{temp_dir_path.join("recipe.rb")} --git-user-name=dummy --message=dummy --pr-title=dummy --pr-source-branch=dummy --dry-run"

      test_txt = File.read(temp_dir_path.join("test.txt"))
      expect(test_txt).to eq "Hi, name!\n"
    end
  end

  # @param command [String]
  def sh(command)
    puts "$ #{command}"
    ret = system(command)
    raise "'#{command}' is failed" unless ret
  end
end
