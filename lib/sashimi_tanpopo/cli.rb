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
      option :target_dir, type: :string, aliases: "-d", desc: "Target directory. Default: current directory"
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
    option :git_user_name,       type: :string,  desc: "user name for git commit. Default: username of user authenticated with token"
    option :git_email,           type: :string,  desc: "email for git commit. Default: <git_user_name>@users.noreply.<github_host>"
    option :message,             type: :string,  desc: "commit message", required: true, aliases: "-m", banner: "COMMIT_MESSAGE"
    option :github_repository,   type: :string,  desc: "GitHub repository for Pull Request. One of --github--repository or $GITHUB_REPOSITORY is required [$GITHUB_REPOSITORY]", banner: "user/repo"
    option :github_api_url,      type: :string,  desc: "GitHub API endpoint. One of --github-api-url or $GITHUB_API_URL is required [$GITHUB_API_URL]", default: "https://api.github.com"
    option :github_token,        type: :string,  desc: "GitHub access token. One of --github-token or $GITHUB_TOKEN is required [$GITHUB_TOKEN]"
    option :github_step_summary, type: :string,  desc: "Path to GitHub step summary file [$GITHUB_STEP_SUMMARY]"
    option :pr_title,            type: :string,  desc: "Pull Request title", required: true
    option :pr_body,             type: :string,  desc: "Pull Request body"
    option :pr_source_branch,    type: :string,  desc: "Pull Request source branch (a.k.a. head branch)", required: true, banner: "pr_branch"
    option :pr_target_branch,    type: :string,  desc: "Pull Request target branch (a.k.a. base branch). Default: default branch of repository (e.g. main, master)", banner: "main"
    option :pr_assignees,        type: :array,   desc: "Pull Request assignees", default: []
    option :pr_reviewers,        type: :array,   desc: "Pull Request reviewers", default: []
    option :pr_labels,           type: :array,   desc: "Pull Request labels", default: []
    option :pr_draft,            type: :boolean, desc: "Whether to create draft Pull Request", default: false
    def github(*recipe_files)
      repository   = option_or_env!(option_name: :github_repository, env_name: "GITHUB_REPOSITORY")
      api_endpoint = option_or_env!(option_name: :github_api_url,    env_name: "GITHUB_API_URL")
      access_token = option_or_env!(option_name: :github_token,      env_name: "GITHUB_TOKEN")

      summary_path = option_or_env(option_name: :github_step_summary, env_name: "GITHUB_STEP_SUMMARY")

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
        pr_target_branch: options[:pr_target_branch],
        pr_assignees:     options[:pr_assignees],
        pr_reviewers:     options[:pr_reviewers],
        pr_labels:        options[:pr_labels],
        is_draft_pr:      options[:pr_draft],
        summary_path:     summary_path,
      ).perform
    end

    desc "gitlab RECIPE [RECIPE...]", "Change local files using recipe files and create Merge Request"
    define_exec_common_options
    option :git_user_name,     type: :string,  desc: "user name for git commit. Default: username of user authenticated with token"
    option :git_email,         type: :string,  desc: "email for git commit. Default: <git_user_name>@noreply.<gitlab_host>"
    option :message,           type: :string,  desc: "commit message", required: true, aliases: "-m", banner: "COMMIT_MESSAGE"
    option :gitlab_project,    type: :string,  desc: "GitLab project for Merge Request. One of --gitlab-project, $GITLAB_PROJECT or $CI_PROJECT_PATH is required [$GITLAB_PROJECT, $CI_PROJECT_PATH]", banner: "user/repo"
    option :gitlab_api_url,    type: :string,  desc: "GitLab API endpoint. One of --gitlab-api-url, $GITLAB_API_URL or $CI_API_V4_URL is required [$GITLAB_API_URL, $CI_API_V4_URL]", default: "https://gitlab.com/api/v4"
    option :gitlab_token,      type: :string,  desc: "GitLab access token. One of --gitlab-token or $GITLAB_TOKEN is required [$GITLAB_TOKEN]"
    option :mr_title,          type: :string,  desc: "Merge Request title", required: true
    option :mr_body,           type: :string,  desc: "Merge Request body"
    option :mr_source_branch,  type: :string,  desc: "Merge Request source branch", required: true, banner: "mr_branch"
    option :mr_target_branch,  type: :string,  desc: "Merge Request target branch. Default: default branch of project (e.g. main, master)", banner: "main"
    option :mr_assignees,      type: :array,   desc: "Merge Request assignees", default: []
    option :mr_reviewers,      type: :array,   desc: "Merge Request reviewers", default: []
    option :mr_labels,         type: :array,   desc: "Merge Request labels", default: []
    option :mr_draft,          type: :boolean, desc: "Whether to create draft Merge Request", default: false
    option :mr_auto_merge,     type: :boolean, desc: "Whether to set auto-merge to Merge Request", default: false
    def gitlab(*recipe_files)
      repository       = option_or_env!(option_name: :gitlab_project,   env_name: %w[GITLAB_PROJECT CI_PROJECT_PATH])
      api_endpoint     = option_or_env!(option_name: :gitlab_api_url,   env_name: %w[GITLAB_API_URL CI_API_V4_URL])
      access_token     = option_or_env!(option_name: :gitlab_token,     env_name: "GITLAB_TOKEN")

      Provider::GitLab.new(
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
        mr_title:         options[:mr_title],
        mr_body:          options[:mr_body],
        mr_source_branch: options[:mr_source_branch],
        mr_target_branch: options[:mr_target_branch],
        mr_assignees:     options[:mr_assignees],
        mr_reviewers:     options[:mr_reviewers],
        mr_labels:        options[:mr_labels],
        is_draft_mr:      options[:mr_draft],
        is_auto_merge:    options[:mr_auto_merge],
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
      # @param env_name [String, Array<String>]
      # @param default [String,nil]
      # @return [String,nil]
      def option_or_env(option_name:, env_name:, default:  nil)
        return options[option_name] if options[option_name] && !options[option_name].empty?

        env_names = Array(env_name) #: Array[String]
        env_names.each do |name|
          return ENV[name] unless ENV.fetch(name, "") == ""
        end

        default
      end

      # @param option_name [String,Symbol]
      # @param env_name [String, Array<String>]
      # @return [String]
      def option_or_env!(option_name:, env_name:)
        value = option_or_env(option_name: option_name, env_name: env_name)
        return value if value

        env_names = Array(env_name)
        SashimiTanpopo.logger.error "Error: One of --#{option_name.to_s.gsub("_", "-")}, #{env_names.join(", ")} is required!"
        exit!
      end
    end
  end
end
