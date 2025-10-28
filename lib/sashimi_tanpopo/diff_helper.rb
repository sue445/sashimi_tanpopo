# frozen_string_literal: true

module SashimiTanpopo
  module DiffHelper
    # Generate diff between 2 strings
    #
    # @param str1 [String]
    # @param str2 [String]
    # @param is_colored [Boolean]
    #
    # @return [String]
    def self.generate_diff(str1, str2, is_colored:)
      format = is_colored ? :color : :text
      Diffy::Diff.new(str1, str2, context: 3).to_s(format)
    end
  end
end
