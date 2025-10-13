# frozen_string_literal: true

module SashimiTanpopo
  class FileUpdater
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
    # @example Responce format
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
    # @example Responce format
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
      # passed from `--params`
      # @!attribute [r] params
      # @return [Hash<Symbol, String>]
      attr_reader :params

      # @!attribute [r] changed_files
      # @return [Hash<String, { before_content: String, after_content: String, mode: String }>] key: file path, value: Hash
      attr_reader :changed_files

      # @param params [Hash<Symbol, String>]
      # @param dry_run [Boolean]
      # @param is_colored [Boolean] Whether show color diff
      # @param target_dir [String]
      # @param is_update_local [Boolean] Whether update local file in `update_file`
      def initialize(params:, dry_run:, is_colored:, target_dir:, is_update_local:)
        @params = params
        @dry_run = dry_run
        @target_dir = target_dir
        @is_update_local = is_update_local
        @changed_files = {}

        @diffy_format = is_colored ? :color : :text
      end

      # Update files if exists
      #
      # @param pattern [String] Path to target file. This supports [`Dir.glob`](https://ruby-doc.org/current/Dir.html#method-c-glob) pattern. e.g. `.github/workflows/*.yml`
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
          full_file_path = File.join(@target_dir, path)
          before_content = File.read(full_file_path)

          SashimiTanpopo.logger.info "Checking #{full_file_path}"

          after_content = update_single_file(path, &block)

          unless after_content
            SashimiTanpopo.logger.info "#{full_file_path} isn't changed"
            next
          end

          @changed_files[path] = {
            before_content: before_content,
            after_content:  after_content,
            mode:           File.stat(full_file_path).mode.to_s(8)
          }

          if @dry_run
            SashimiTanpopo.logger.info "#{full_file_path} will be changed (dryrun)"
          else
            SashimiTanpopo.logger.info "#{full_file_path} is changed"
          end
        end
      end

      private

      # @param path [String]
      # @param block [Proc]
      # @yieldparam content [String] content of file
      #
      # @return [String] Content of changed file if file is changed
      # @return [nil] file isn't changed
      def update_single_file(path, &block)
        return nil unless File.exist?(path)

        content = File.read(path)
        before_content = content.dup

        yield content

        # File isn't changed
        return nil if content == before_content

        show_diff(before_content, content)

        File.write(path, content) if !@dry_run && @is_update_local

        content
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
