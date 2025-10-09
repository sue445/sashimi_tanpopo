# frozen_string_literal: true

module SashimiTanpopo
  class FileUpdater
    # @param recipe_body [String]
    # @param recipe_path [String]
    # @param target_dir [String]
    # @param params [Hash<Symbol, String>]
    # @param dry_run [Boolean]
    def evaluate(recipe_body:, recipe_path:, target_dir:, params:, dry_run:)
      context = EvalContext.new(params: params, dry_run: dry_run)
      InstanceEval.new(recipe_body: recipe_body, recipe_path: recipe_path, target_dir: target_dir, context: context).call
    end

    class EvalContext
      # @!attribute [r] params
      # @return [Hash<Symbol, String>]
      attr_reader :params

      # @param params [Hash<Symbol, String>]
      # @param dry_run [Boolean]
      def initialize(params:, dry_run:)
        @params = params
        @dry_run = dry_run
      end

      # @param path [String]
      # @yieldparam content [String] content of file
      def update_file(path)
        return unless File.exist?(path)

        content = File.read(path)

        result = yield content.dup

        # File isn't changed
        return if content == result

        if @dry_run
          # TODO: Do after
        else
          File.write(path, result)
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
