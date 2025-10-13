# frozen_string_literal: true

module SashimiTanpopo
  module Provider
    class Base
      # @param recipe_paths [Array<String>]
      # @param target_dir [String]
      # @param params [Hash<Symbol, String>]
      # @param dry_run [Boolean]
      # @param is_colored [Boolean] Whether show color diff
      # @param is_update_local [Boolean] Whether update local file in `update_file`
      def initialize(recipe_paths:, target_dir:, params:, dry_run:, is_colored:, is_update_local:)
        @recipe_paths = recipe_paths
        @target_dir = target_dir
        @params = params
        @dry_run = dry_run
        @is_colored = is_colored
        @is_update_local = is_update_local
      end

      # Apply recipe files
      #
      # @return [Hash<String, { before_content: String, after_content: String, mode: String }>] changed files (key: file path, value: Hash)
      #
      # @example Responce format
      #   {
      #     "path/to/changed-file.txt" => {
      #       before_content: "foo",
      #       after_content:  "bar",
      #       mode:           "100644",
      #     }
      #   }
      def apply_recipe_files
        all_changed_files = {} # : changed_files

        @recipe_paths.each do |recipe_path|
          changed_files =
            FileUpdater.new.perform(
              recipe_path:     recipe_path,
              target_dir:      @target_dir,
              params:          @params,
              dry_run:         @dry_run,
              is_colored:      @is_colored,
              is_update_local: @is_update_local,
            )

          all_changed_files.merge!(changed_files)
        end

        all_changed_files
      end
    end
  end
end
