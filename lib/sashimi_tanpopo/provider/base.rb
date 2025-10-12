# frozen_string_literal: true

module SashimiTanpopo
  module Provider
    class Base
      # @param recipe_paths [Array<String>]
      # @param target_dir [String]
      # @param params [Hash<Symbol, String>]
      # @param dry_run [Boolean]
      # @param is_colored [Boolean] Whether show color diff
      def initialize(recipe_paths:, target_dir:, params:, dry_run:, is_colored:)
        @recipe_paths = recipe_paths
        @target_dir = target_dir
        @params = params
        @dry_run = dry_run
        @is_colored = is_colored
      end
    end
  end
end
