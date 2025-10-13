# frozen_string_literal: true

module SashimiTanpopo
  module Provider
    # Apply recipe files to local
    class Local < Base
      # @param recipe_paths [Array<String>]
      # @param target_dir [String]
      # @param params [Hash<Symbol, String>]
      # @param dry_run [Boolean]
      # @param is_colored [Boolean] Whether show color diff
      def initialize(recipe_paths:, target_dir:, params:, dry_run:, is_colored:)
        super(
          recipe_paths:    recipe_paths,
          target_dir:      target_dir,
          params:          params,
          dry_run:         dry_run,
          is_colored:      is_colored,
          is_update_local: true
        )
      end

      def perform
        apply_recipe_files
      end
    end
  end
end
