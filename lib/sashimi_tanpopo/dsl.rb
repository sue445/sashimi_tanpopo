# frozen_string_literal: true

module SashimiTanpopo
  class DSL
    # Apply recipe file
    #
    # @param recipe_path [String]
    # @param target_dir [String]
    # @param params [Hash<Symbol, String>]
    # @param dry_run [Boolean]
    # @param is_colored [Boolean] Whether show color diff
    # @param is_update_local [Boolean] Whether update local file in `update_file`
    #
    # @return [Hash<String, { before_content: String, after_content: String, mode: String }>] changed files (key: file path, value: Hash)
    #
    # @example Response format
    #   {
    #     "path/to/changed-file.txt" => {
    #       before_content: "foo",
    #       after_content:  "bar",
    #       mode:           "100644",
    #     }
    #   }
    def perform(recipe_path:, target_dir:, params:, dry_run:, is_colored:, is_update_local:)
      evaluate(
        recipe_body:     File.read(recipe_path),
        recipe_path:     recipe_path,
        target_dir:      target_dir,
        params:          params,
        dry_run:         dry_run,
        is_colored:      is_colored,
        is_update_local: is_update_local,
      )
    end

    # Apply recipe file for unit test
    #
    # @param recipe_body [String]
    # @param recipe_path [String]
    # @param target_dir [String]
    # @param params [Hash<Symbol, String>]
    # @param dry_run [Boolean]
    # @param is_colored [Boolean] Whether show color diff
    # @param is_update_local [Boolean] Whether update local file in `update_file`
    #
    # @return [Hash<String, { before_content: String, after_content: String, mode: String }>] changed files (key: file path, value: Hash)
    #
    # @example Response format
    #   {
    #     "path/to/changed-file.txt" => {
    #       before_content: "foo",
    #       after_content:  "bar",
    #       mode:           "100644",
    #     }
    #   }
    def evaluate(recipe_body:, recipe_path:, target_dir:, params:, dry_run:, is_colored:, is_update_local:)
      context = EvalContext.new(params: params, dry_run: dry_run, is_colored: is_colored, target_dir: target_dir, is_update_local: is_update_local)
      InstanceEval.new(recipe_body: recipe_body, recipe_path: recipe_path, target_dir: target_dir, context: context).call
      context.changed_files
    end

    class EvalContext
      # @param params [Hash<Symbol, String>]
      # @param dry_run [Boolean]
      # @param is_colored [Boolean] Whether show color diff
      # @param target_dir [String]
      # @param is_update_local [Boolean] Whether update local file in `update_file`
      def initialize(params:, dry_run:, is_colored:, target_dir:, is_update_local:)
        @__params__ = params
        @__dry_run__ = dry_run
        @__target_dir__ = target_dir
        @__is_update_local__ = is_update_local
        @__is_colored__ = is_colored
      end

      # passed from `--params`
      #
      # @return [Hash<Symbol, String>]
      #
      # @example Pass params via `--params`
      #   sashimi_tanpopo local --params name:sue445 --params lang:ja recipe.rb
      #
      # @example within `recipe.rb`
      #   # recipe.rb
      #
      #   params
      #   #=> {name: "sue445", lang: "ja"}
      def params
        @__params__
      end

      # @return [Hash<String, { before_content: String, after_content: String, mode: String }>] key: file path, value: Hash
      def changed_files
        @__changed_files__ ||= {}
      end

      # @return [Boolean] Whether dry run
      #
      # @example
      #   unless dry_run?
      #     puts "This will be called when apply mode"
      #   end
      def dry_run?
        @__dry_run__
      end

      # Update files if exists
      #
      # @param pattern [String] Path to target file (relative path from `--target-dir`). This supports [`Dir.glob`](https://ruby-doc.org/current/Dir.html#method-c-glob) pattern. (e.g. `.github/workflows/*.yml`)
      #
      # @yieldparam content [String] Content of file. If `content` is changed in block, file will be changed.
      #
      # @example Update single file
      #   update_file "test.txt" do |content|
      #     content.gsub!("name", params[:name])
      #   end
      #
      # @example Update multiple files
      #   update_file ".github/workflows/*.yml" do |content|
      #     content.gsub!(/ruby-version: "(.+)"/, %Q{ruby-version: "#{params[:ruby_version]}"})
      #   end
      def update_file(pattern, &block)
        Dir.glob(pattern).each do |path|
          full_file_path = File.join(@__target_dir__, path)

          next unless File.exist?(full_file_path)

          before_content =
            if changed_files[path]
              changed_files[path][:after_content]
            else
              File.read(full_file_path)
            end

          SashimiTanpopo.logger.info "Checking #{full_file_path}"

          after_content = update_single_file(before_content, &block)

          unless after_content
            SashimiTanpopo.logger.info "#{full_file_path} isn't changed"
            next
          end

          File.write(full_file_path, after_content) if !dry_run? && @__is_update_local__

          changed_files[path] ||= {
            before_content: before_content,
            mode:           File.stat(full_file_path).mode.to_s(8)
          }

          changed_files[path][:after_content] = after_content

          if dry_run?
            SashimiTanpopo.logger.info "#{full_file_path} will be changed (dryrun)"
          else
            SashimiTanpopo.logger.info "#{full_file_path} is changed"
          end
        end
      end

      private

      # @param content [String]
      #
      # @yieldparam content [String] content of file
      #
      # @return [String] Content of changed file if file is changed
      # @return [nil] file isn't changed
      def update_single_file(content)
        after_content = content.dup

        yield after_content

        # File isn't changed
        return nil if after_content == content

        show_diff(content, after_content)

        after_content
      end

      # @param str1 [String]
      # @param str2 [String]
      def show_diff(str1, str2)
        diff_text = DiffHelper.generate_diff(str1, str2, is_colored: @__is_colored__)

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
    private_constant :InstanceEval
  end
end
