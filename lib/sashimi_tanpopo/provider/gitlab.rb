# frozen_string_literal: true

module SashimiTanpopo
  module Provider
    # Apply recipe files and create Pull Request
    class GitLab < Base
      DEFAULT_API_ENDPOINT = "https://gitlab.com/api/v4"

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
      # @param mr_title [String]
      # @param mr_body [String]
      # @param mr_source_branch [String] Pull Request source branch
      # @param mr_target_branch [String] Pull Request target branch
      # @param mr_assignees [Array<String>]
      # @param mr_reviewers [Array<String>]
      # @param mr_labels [Array<String>]
      # @param is_draft_mr [Boolean] Whether create draft Pull Request
      def initialize(recipe_paths:, target_dir:, params:, dry_run:, is_colored:,
                     git_username:, git_email:, commit_message:,
                     repository:, access_token:, api_endpoint: DEFAULT_API_ENDPOINT,
                     mr_title:, mr_body:, mr_source_branch:, mr_target_branch:,
                     mr_assignees: [], mr_reviewers: [], mr_labels: [], is_draft_mr:)
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
        @mr_title = mr_title
        @mr_body = mr_body
        @mr_source_branch = mr_source_branch
        @mr_target_branch = mr_target_branch
        @mr_assignees = mr_assignees
        @mr_reviewers = mr_reviewers
        @mr_labels = mr_labels
        @is_draft_mr = is_draft_mr
        @git_username = git_username
        @git_email = git_email
      end

      # Apply recipe files
      # @return [String] Created Merge Request URL
      # @return [nil] Merge Request isn't created
      def perform
        changed_files = apply_recipe_files

        return nil if changed_files.empty? || @dry_run
        
        # TODO: Impl
      end
    end
  end
end
