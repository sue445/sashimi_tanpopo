# frozen_string_literal: true

module SashimiTanpopo
  class FileUpdater
    # @param recipe_body [String]
    # @param recipe_path [String]
    # @param target_dir [String]
    # @param params [Hash<Symbol, String>]
    # @param dry_run [Boolean]
    # @param is_colored [Boolean] Whether show color diff
    def evaluate(recipe_body:, recipe_path:, target_dir:, params:, dry_run:, is_colored:)
      context = EvalContext.new(params: params, dry_run: dry_run, is_colored: is_colored)
      InstanceEval.new(recipe_body: recipe_body, recipe_path: recipe_path, target_dir: target_dir, context: context).call
    end

    class EvalContext
      # @!attribute [r] params
      # @return [Hash<Symbol, String>]
      attr_reader :params

      # @param params [Hash<Symbol, String>]
      # @param dry_run [Boolean]
      # @param is_colored [Boolean] Whether show color diff
      def initialize(params:, dry_run:, is_colored:)
        @params = params
        @dry_run = dry_run

        @diffy_format = is_colored ? :color : :text
      end

      # @param path [String]
      # @yieldparam content [String] content of file
      def update_file(path)
        return unless File.exist?(path)

        content = File.read(path)

        result = yield content.dup

        # File isn't changed
        return if content == result

        show_diff(content, result)

        return if @dry_run

        File.write(path, result)
      end

      private

      # @param str1 [String]
      # @param str2 [String]
      def show_diff(str1, str2)
        diff_text = Diffy::Diff.new(str1, str2).to_s(@diffy_format)

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
