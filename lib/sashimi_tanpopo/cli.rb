# frozen_string_literal: true

require "thor"
require "sashimi_tanpopo"

module SashimiTanpopo
  class CLI < Thor
    desc "version", "Show sashimi_tanpopo version"
    def version
      puts "sashimi_tanpopo v#{SashimiTanpopo::VERSION}"
    end

    def self.exit_on_failure?
      true
    end

    def self.define_exec_common_options
      option :target_dir, type: :string, aliases: "-d", default: Dir.pwd, desc: "Target directory"
      option :params,     type: :hash, aliases: "-p", default: {}, desc: "Params passed to recipe file", repeatable: true
      option :dry_run,    type: :boolean, default: false, desc: "Whether to run dry run"
      option :color,      type: :boolean, default: true, desc: "Whether to colorize output"
    end

    desc "local RECIPE [RECIPE...]", "Change local files using recipe files"
    define_exec_common_options
    def local(*recipe_files)
      Provider::Local.new(
        recipe_paths: recipe_files,
        target_dir:   options[:target_dir],
        params:       self.class.normalize_params(options[:params]),
        dry_run:      options[:dry_run],
        is_colored:   options[:color],
      ).perform
    end

    desc "github RECIPE [RECIPE...]", "Change local files using recipe files and create Pull Request"
    define_exec_common_options
    option :git_user_name,     type: :string,  desc: "user name for git commit. default: username of user authenticated with token"
    option :git_email,         type: :string,  desc: "email for git commit. default: <git_user_name>@users.noreply.<github_host>"
    option :message,           type: :string,  desc: "commit message", required: true, aliases: "-m"
    option :github_repository, type: :string,  desc: "GitHub repository for Pull Request [$GITHUB_REPOSITORY]", required: true, banner: "user/repo"
    option :github_api_url,    type: :string,  desc: "GitHub API endpoint. Either --github-api-url or $GITHUB_API_URL is required [$GITHUB_API_URL]", default: "https://api.github.com"
    option :github_token,      type: :string,  desc: "GitHub access token. Either --github-token or $GITHUB_TOKEN is required [$GITHUB_TOKEN]"
    option :pr_title,          type: :string,  desc: "Pull Request title", required: true
    option :pr_body,           type: :string,  desc: "Pull Request body"
    option :pr_source_branch,  type: :string,  desc: "Pull Request source branch (a.k.a. head branch)", required: true, banner: "pr_branch"
    option :pr_target_branch,  type: :string,  desc: "Pull Request target branch (a.k.a. base branch). Either --pr-target-branch or $GITHUB_REF_NAME is required [$GITHUB_REF_NAME]", required: true, banner: "main"
    option :pr_assignees,      type: :array,   desc: "Pull Request assignees", default: []
    option :pr_reviewers,      type: :array,   desc: "Pull Request reviewers", default: []
    option :pr_labels,         type: :array,   desc: "Pull Request labels", default: []
    option :pr_draft,          type: :boolean, desc: "Whether to create draft Pull Request", default: false
    def github(*recipe_files)
      repository       = option_or_env!(:github_repository, "GITHUB_REPOSITORY")
      api_endpoint     = option_or_env!(:github_api_url, "GITHUB_API_URL")
      access_token     = option_or_env!(:github_token, "GITHUB_TOKEN")
      pr_target_branch = option_or_env!(:pr_target_branch, "GITHUB_REF_NAME")

      Provider::GitHub.new(
        recipe_paths:     recipe_files,
        target_dir:       options[:target_dir],
        params:           self.class.normalize_params(options[:params]),
        dry_run:          options[:dry_run],
        is_colored:       options[:color],
        git_username:     options[:git_user_name],
        git_email:        options[:git_email],
        commit_message:   options[:message],
        repository:       repository,
        api_endpoint:     api_endpoint,
        access_token:     access_token,
        pr_title:         options[:pr_title],
        pr_body:          options[:pr_body],
        pr_source_branch: options[:pr_source_branch],
        pr_target_branch: pr_target_branch,
        pr_assignees:     options[:pr_assignees],
        pr_reviewers:     options[:pr_reviewers],
        pr_labels:        options[:pr_labels],
        is_draft_pr:      options[:pr_draft],
      ).perform
    end

    # @param params [Hash<String, String>]
    # @return [Hash<Symbol,String>]
    #
    # @example
    #   normalize_params({"k1"=>"v1", "k2"=>"v2"})
    #   #=> {k1: "v1", k2: "v2"}
    def self.normalize_params(params)
      params.transform_keys(&:to_sym)
    end

    private

    no_commands do
      # @param option_name [String,Symbol]
      # @param env_name [String]
      # @param default [String,nil]
      # @return [String,nil]
      def option_or_env(option_name, env_name, default = nil)
        return options[option_name] if options[option_name] && !options[option_name].empty?
        return ENV[env_name] unless ENV.fetch(env_name, "") == ""
        default
      end

      # @param option_name [String,Symbol]
      # @param env_name [String]
      # @return [String]
      def option_or_env!(option_name, env_name)
        value = option_or_env(option_name, env_name)
        return value if value

        puts "Error: Either --#{option_name.to_s.gsub("_", "-")} or #{env_name} is required!"
        exit!
      end
    end
  end
end
