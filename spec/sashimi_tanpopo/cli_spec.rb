# frozen_string_literal: true

RSpec.describe SashimiTanpopo::CLI do
  describe ".normalize_params" do
    subject { SashimiTanpopo::CLI.normalize_params(params) }

    let(:params) { {"k1"=>"v1", "k2"=>"v2"} }

    it { should eq({ k1: "v1", k2: "v2" }) }
  end
end
