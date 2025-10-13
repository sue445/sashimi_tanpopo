# frozen_string_literal: true

module SashimiTanpopo
  module Provider
    # Apply recipe files and create Pull Request
    class GitHub < Base
      DEFAULT_API_ENDPOINT = "https://api.github.com/"

      DEFAULT_GITHUB_HOST = "github.com"

      # @param recipe_paths [Array<String>]
      # @param target_dir [String,nil]
      # @param params [Hash<Symbol, String>]
      # @param dry_run [Boolean]
      # @param is_colored [Boolean] Whether show color diff
      # @param git_username [String,nil]
      # @param git_email [String,nil]
      # @param commit_message [String]
      # @param repository [String]
      # @param access_token [String]
      # @param api_endpoint [String]
      # @param pr_title [String]
      # @param pr_body [String]
      # @param pr_source_branch [String] Pull Request source branch (a.k.a. head branch)
      # @param pr_target_branch [String] Pull Request target branch (a.k.a. base branch)
      # @param pr_assignees [Array<String>]
      # @param pr_reviewers [Array<String>]
      # @param pr_labels [Array<String>]
      # @param is_draft_pr [Boolean] Whether create draft Pull Request
      def initialize(recipe_paths:, target_dir:, params:, dry_run:, is_colored:,
                     git_username:, git_email:, commit_message:,
                     repository:, access_token:, api_endpoint: DEFAULT_API_ENDPOINT,
                     pr_title:, pr_body:, pr_source_branch:, pr_target_branch:,
                     pr_assignees: [], pr_reviewers: [], pr_labels: [], is_draft_pr:)
        super(
          recipe_paths:    recipe_paths,
          target_dir:      target_dir,
          params:          params,
          dry_run:         dry_run,
          is_colored:      is_colored,
          is_update_local: false,
        )

        @commit_message = commit_message
        @repository = repository
        @pr_title = pr_title
        @pr_body = pr_body
        @pr_source_branch = pr_source_branch
        @pr_target_branch = pr_target_branch
        @pr_assignees = pr_assignees
        @pr_reviewers = pr_reviewers
        @pr_labels = pr_labels
        @is_draft_pr = is_draft_pr

        @client = Octokit::Client.new(api_endpoint: api_endpoint, access_token: access_token)

        @git_username =
          if git_username
            git_username
          else
            current_user_name
          end

        @git_email =
          if git_email
            git_email
          else
            "#{@git_username}@users.noreply.#{self.class.github_host(api_endpoint)}"
          end
      end

      # Apply recipe files
      # @return [String] Created Pull Request URL
      # @return [nil] Pull Request isn't created
      def perform
        changed_files = apply_recipe_files

        return nil if changed_files.empty? || @dry_run

        create_branch_and_push_changes(changed_files)

        pr = create_pull_request

        add_pr_labels(pr[:number])
        add_pr_assignees(pr[:number])
        add_pr_reviewers(pr[:number])

        pr[:html_url]
      end

      # Get GitHub host from api_endpoint
      # @param api_endpoint [String]
      # @return [String]
      def self.github_host(api_endpoint)
        return DEFAULT_GITHUB_HOST if api_endpoint == DEFAULT_API_ENDPOINT

        matched = %r{^https?://(.+)/api}.match(api_endpoint)
        return matched[1] if matched # steep:ignore

        DEFAULT_GITHUB_HOST
      end

      private

      # @return [String]
      def current_user_name
        @client.user[:login]
      end

      # Create branch on repository and push changes
      def create_branch_and_push_changes(changed_files)
        current_ref = @client.ref(@repository, "heads/#{@pr_target_branch}")
        branch_ref = @client.create_ref(@repository, "heads/#{@pr_source_branch}", current_ref.object.sha) # steep:ignore

        branch_commit = @client.commit(@repository, branch_ref.object.sha) # steep:ignore

        tree_metas =
          changed_files.map do |path, data|
            create_tree_meta(path: path, body: data[:after_content], mode: data[:mode])
          end
        tree = @client.create_tree(@repository, tree_metas, base_tree: branch_commit.commit.tree.sha) # steep:ignore

        commit = @client.create_commit(
          @repository,
          @commit_message,
          tree.sha, # steep:ignore
          branch_ref.object.sha, # steep:ignore
          author: {
            name: @git_username,
            email: @git_email,
          }
        )

        @client.update_ref(@repository, "heads/#{@pr_source_branch}", commit.sha) # steep:ignore
      end

      # @param path [String]
      # @param body [String]
      # @param mode [String]
      def create_tree_meta(path:, body:, mode:)
        file_body_sha = @client.create_blob(@repository, body)

        {
          path: path,
          mode: mode,
          type: "blob",
          sha:  file_body_sha,
        }
      end

      # @return [Hash{pr_number: Integer, html_url: String}] Created Pull Request info
      def create_pull_request
        pr = @client.create_pull_request(@repository, @pr_target_branch, @pr_source_branch, @pr_title, @pr_body, draft: @is_draft_pr)

        SashimiTanpopo.logger.info "Pull Request is created: #{pr[:html_url]}"

        {
          number: pr[:number],
          html_url: pr[:html_url],
        }
      end

      # @param pr_number [Integer]
      def add_pr_labels(pr_number)
        return if @pr_labels.empty?

        @client.add_labels_to_an_issue(@repository, pr_number, @pr_labels)
      end

      # @param pr_number [Integer]
      def add_pr_assignees(pr_number)
        return if @pr_assignees.empty?

        @client.add_assignees(@repository, pr_number, @pr_assignees)
      end

      # @param pr_number [Integer]
      def add_pr_reviewers(pr_number)
        return if @pr_reviewers.empty?

        @client.request_pull_request_review(@repository, pr_number, reviewers: @pr_reviewers)
      end
    end
  end
end
