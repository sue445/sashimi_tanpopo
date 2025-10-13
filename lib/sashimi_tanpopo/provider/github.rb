# frozen_string_literal: true

module SashimiTanpopo
  module Provider
    class GitHub < Base
      # @param recipe_paths [Array<String>]
      # @param target_dir [String]
      # @param params [Hash<Symbol, String>]
      # @param dry_run [Boolean]
      # @param is_colored [Boolean] Whether show color diff
      # @param git_username [String]
      # @param git_email [String]
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
      def initialize(recipe_paths:, target_dir:, params:, dry_run:, is_colored:,
                     git_username:, git_email:, commit_message:,
                     repository:, access_token:, api_endpoint: "https://api.github.com/",
                     pr_title:, pr_body:, pr_source_branch:, pr_target_branch:,
                     pr_assignees: [], pr_reviewers: [], pr_labels: [])
        super(
          recipe_paths: recipe_paths,
          target_dir:   target_dir,
          params:       params,
          dry_run:      dry_run,
          is_colored:   is_colored,
        )

        @git_username = git_username
        @git_email = git_email
        @commit_message = commit_message
        @repository = repository
        @pr_title = pr_title
        @pr_body = pr_body
        @pr_source_branch = pr_source_branch
        @pr_target_branch = pr_target_branch
        @pr_assignees = pr_assignees
        @pr_reviewers = pr_reviewers
        @pr_labels = pr_labels

        @client = Octokit::Client.new(api_endpoint: api_endpoint, access_token: access_token)
      end

      def perform
        changed_file_paths = apply_recipe_files

        return if changed_file_paths.empty? || @dry_run

        create_branch_and_push_changes(changed_file_paths)

        pr_number = create_pull_request

        add_pr_labels(pr_number)
        add_pr_assignees(pr_number)
        add_pr_reviewers(pr_number)

        # TODO: Impl
        # TODO: restore files
      end

      private

      # Create branch on repository and push changes
      def create_branch_and_push_changes(changed_file_paths)
        current_ref = @client.ref(@repository, "heads/#{@pr_target_branch}")
        branch_ref = @client.create_ref(@repository, "heads/#{@pr_source_branch}", current_ref.object.sha) # steep:ignore

        branch_commit = @client.commit(@repository, branch_ref.object.sha) # steep:ignore

        tree_metas = changed_file_paths.map { |file_path| create_tree_meta(file_path) }
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

      # @param file_path [String]
      def create_tree_meta(file_path)
        full_file_path = File.join(@target_dir, file_path)
        file_body = File.read(full_file_path)
        file_body_sha = @client.create_blob(@repository, file_body)

        {
          path: file_path,
          mode: File.stat(full_file_path).mode.to_s(8),
          type: "blob",
          sha:  file_body_sha,
        }
      end

      # @return [Integer] Created Pull Request number
      def create_pull_request
        pr = @client.create_pull_request(@repository, @pr_target_branch, @pr_source_branch, @pr_title, @pr_body)
        pr[:number]
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
