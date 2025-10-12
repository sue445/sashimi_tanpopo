# frozen_string_literal: true

module SashimiTanpopo
  class FileUpdater
    # @param recipe_path [String]
    # @param target_dir [String]
    # @param params [Hash<Symbol, String>]
    # @param dry_run [Boolean]
    # @param is_colored [Boolean] Whether show color diff
    #
    # @return [Array<String>] changed file paths
    def perform(recipe_path:, target_dir:, params:, dry_run:, is_colored:)
      evaluate(
        recipe_body: File.read(recipe_path),
        recipe_path: recipe_path,
        target_dir:  target_dir,
        params:      params,
        dry_run:     dry_run,
        is_colored:  is_colored,
      )
    end

    # @param recipe_body [String]
    # @param recipe_path [String]
    # @param target_dir [String]
    # @param params [Hash<Symbol, String>]
    # @param dry_run [Boolean]
    # @param is_colored [Boolean] Whether show color diff
    #
    # @return [Array<String>] changed file paths
    def evaluate(recipe_body:, recipe_path:, target_dir:, params:, dry_run:, is_colored:)
      context = EvalContext.new(params: params, dry_run: dry_run, is_colored: is_colored, target_dir: target_dir)
      InstanceEval.new(recipe_body: recipe_body, recipe_path: recipe_path, target_dir: target_dir, context: context).call
      context.changed_file_paths
    end

    class EvalContext
      # @!attribute [r] params
      # @return [Hash<Symbol, String>]
      attr_reader :params

      # @!attribute [r] changed_file_paths
      # @return [Array<String>]
      attr_reader :changed_file_paths

      # @param params [Hash<Symbol, String>]
      # @param dry_run [Boolean]
      # @param is_colored [Boolean] Whether show color diff
      # @param target_dir [String]
      def initialize(params:, dry_run:, is_colored:, target_dir:)
        @params = params
        @dry_run = dry_run
        @target_dir = target_dir
        @changed_file_paths = []

        @diffy_format = is_colored ? :color : :text
      end

      # @param pattern [String]
      # @param block [Proc]
      # @yieldparam content [String] content of file
      def update_file(pattern, &block)
        Dir.glob(pattern).each do |path|
          is_changed = update_single_file(path, &block)

          if is_changed
            @changed_file_paths << path

            if @dry_run
              SashimiTanpopo.logger.info "#{File.join(@target_dir, path)} will be changed (dryrun)"
            else
              SashimiTanpopo.logger.info "#{File.join(@target_dir, path)} is changed"
            end
          end
        end
      end

      private

      # @param path [String]
      # @param block [Proc]
      # @yieldparam content [String] content of file
      #
      # @return [Boolean] Whether file is changed
      def update_single_file(path, &block)
        return false unless File.exist?(path)

        content = File.read(path)
        before_content = content.dup

        yield content

        # File isn't changed
        return false if content == before_content

        show_diff(before_content, content)

        File.write(path, content) unless @dry_run

        true
      end

      # @param str1 [String]
      # @param str2 [String]
      def show_diff(str1, str2)
        diff_text = Diffy::Diff.new(str1, str2).to_s(@diffy_format) # steep:ignore

        SashimiTanpopo.logger.info "diff:"

        diff_text.each_line do |line|
          SashimiTanpopo.logger.info line
        end
      end
    end

    class InstanceEval
      # @param recipe_body [String]
      # @param recipe_path [String]
      # @param target_dir [String]
      # @param context [EvalContext]
      def initialize(recipe_body:, recipe_path:, target_dir:, context:)
        @code = <<~RUBY
          Dir.chdir(@target_dir) do
            @context.instance_eval do
              eval(#{recipe_body.dump}, nil, #{recipe_path.dump}, 1)
            end
          end
        RUBY

        @target_dir = target_dir
        @context = context
      end

      def call
        eval(@code)
      end
    end
  end
end
