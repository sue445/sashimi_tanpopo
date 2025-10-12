module FixtureUtil
  def fixture(file)
    fixtures_dir.join(file).read
  end
end
