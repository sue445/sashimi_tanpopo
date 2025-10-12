# frozen_string_literal: true

module SashimiTanpopo
  module Provider
    class GitHub < Base
      # @param recipe_paths [Array<String>]
      # @param target_dir [String]
      # @param params [Hash<Symbol, String>]
      # @param dry_run [Boolean]
      # @param is_colored [Boolean] Whether show color diff
      def initialize(recipe_paths:, target_dir:, params:, dry_run:, is_colored:)
        super(
          recipe_paths: recipe_paths,
          target_dir:   target_dir,
          params:       params,
          dry_run:      dry_run,
          is_colored:   is_colored,
        )
      end

      def perform
        apply_recipe_files

        # TODO
      end
    end
  end
end
