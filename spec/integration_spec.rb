# frozen_string_literal: true

RSpec.describe "sashimi_tanpopo" do
  describe "local" do
    include_context "uses temp dir"

    before do
      FileUtils.cp(fixtures_dir.join("test.txt"), temp_dir)
      FileUtils.cp(fixtures_dir.join("recipe.rb"), temp_dir)
    end

    context "with --params" do
      it "run command" do
        sh "#{exe_sashimi_tanpopo} local --target-dir=#{temp_dir} --params=name:sue445 #{temp_dir_path.join("recipe.rb")}"

        test_txt = File.read(temp_dir_path.join("test.txt"))
        expect(test_txt).to eq "Hi, sue445!\n"
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

  # @param command [String]
  def sh(command)
    puts "$ #{command}"
    ret = system(command)
    raise "'#{command}' is failed" unless ret
  end
end
