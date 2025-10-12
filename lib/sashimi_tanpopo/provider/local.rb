# frozen_string_literal: true

module SashimiTanpopo
  module Provider
    class Local < Base
      # @param recipe_paths [Array<String>]
      # @param target_dir [String]
      # @param params [Hash<Symbol, String>]
      # @param dry_run [Boolean]
      # @param is_colored [Boolean] Whether show color diff
      def initialize(recipe_paths:, target_dir:, params:, dry_run:, is_colored:)
        super
      end
    end
  end
end
