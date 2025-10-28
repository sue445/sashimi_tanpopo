# frozen_string_literal: true

RSpec.describe SashimiTanpopo::DiffHelper do
  describe ".generate_diff" do
    subject { SashimiTanpopo::DiffHelper.generate_diff(str1, str2, is_colored: is_colored) }

    let(:is_colored) { false }

    context "simple case" do
      let(:str1) do
        <<~EOS
          0000000000
          1111111111
          2222222222
        EOS
      end

      let(:str2) do
        <<~EOS
          0000000000
          AAAAAAAAAA
          2222222222
        EOS
      end

      let(:expected) do
        <<~EOS
           0000000000
          -1111111111
          +AAAAAAAAAA
           2222222222
        EOS
      end

      it { should eq expected }
    end

    context "many lines" do
      let(:str1) do
        <<~EOS
          0000000000
          1111111111
          2222222222
          3333333333
          4444444444
          5555555555
          6666666666
          7777777777
          8888888888
        EOS
      end

      let(:str2) do
        <<~EOS
          0000000000
          1111111111
          2222222222
          3333333333
          AAAAAAAAAA
          5555555555
          6666666666
          7777777777
          8888888888
        EOS
      end

      let(:expected) do
        <<~EOS
           1111111111
           2222222222
           3333333333
          -4444444444
          +AAAAAAAAAA
           5555555555
           6666666666
           7777777777
        EOS
      end

      it { should eq expected }
    end
  end
end
