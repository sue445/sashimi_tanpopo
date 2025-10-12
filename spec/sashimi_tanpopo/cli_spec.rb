# frozen_string_literal: true

RSpec.describe SashimiTanpopo::CLI do
  describe ".parse_params" do
    subject { SashimiTanpopo::CLI.parse_params(params) }

    let(:params) { %w[k1=v1 k2=v2] }

    it { should eq({ k1: "v1", k2: "v2" }) }
  end
end
