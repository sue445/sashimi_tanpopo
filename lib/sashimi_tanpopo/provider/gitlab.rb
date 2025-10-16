# frozen_string_literal: true

module SashimiTanpopo
  module Provider
    # Apply recipe files and create Pull Request
    class GitLab < Base
      DEFAULT_API_ENDPOINT = "https://gitlab.com/api/v4"

      MAX_RETRY_COUNT = 5

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
      # @param mr_source_branch [String] Merge Request source branch
      # @param mr_target_branch [String] Merge Request target branch
      # @param mr_assignees [Array<String>]
      # @param mr_reviewers [Array<String>]
      # @param mr_labels [Array<String>]
      # @param is_draft_mr [Boolean] Whether create draft Pull Request
      # @param is_auto_merge [Boolean] Whether enable auto-merge
      def initialize(recipe_paths:, target_dir:, params:, dry_run:, is_colored:,
                     git_username:, git_email:, commit_message:,
                     repository:, access_token:, api_endpoint: DEFAULT_API_ENDPOINT,
                     mr_title:, mr_body:, mr_source_branch:, mr_target_branch:,
                     mr_assignees: [], mr_reviewers: [], mr_labels: [], is_draft_mr:, is_auto_merge:)
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
        @is_auto_merge = is_auto_merge
        @git_username = git_username
        @git_email = git_email

        @gitlab = Gitlab.client(endpoint: api_endpoint, private_token: access_token)
      end

      # Apply recipe files
      #
      # @return [String] Created Merge Request URL
      # @return [nil] Merge Request isn't created
      def perform
        changed_files = apply_recipe_files

        return nil if changed_files.empty? || @dry_run

        if exists_branch?(@mr_source_branch)
          SashimiTanpopo.logger.info "Skipped because branch #{@pr_source_branch} already exists on #{@repository}"
          return nil
        end

        create_branch_and_push_changes(changed_files)

        mr = create_merge_request
        SashimiTanpopo.logger.info "Merge Request is created: #{mr[:web_url]}"

        if @is_auto_merge
          set_auto_merge(mr[:iid])
          SashimiTanpopo.logger.info "Set auto-merge to #{mr[:web_url]}"
        end

        mr[:web_url]
      end

      # @param username [String]
      #
      # @return [Integer]
      # @return [nil] user is not found
      #
      # @see https://docs.gitlab.com/api/users/#as-a-regular-user
      def get_user_id_from_user_name(username)
        user = with_retry do
          @gitlab.users(username: username).first
        end
        return nil unless user

        user["id"].to_i
      end

      # @param username [String]
      #
      # @return [Integer]
      #
      # @raise [SashimiTanpopo::NotFoundUserError]
      #
      # @see https://docs.gitlab.com/api/users/#as-a-regular-user
      def get_user_id_from_user_name!(username)
        user_id = get_user_id_from_user_name(username)
        raise NotFoundUserError, "#{username} isn't found" unless user_id

        user_id
      end

      # @param usernames [Array<String>]
      #
      # @return [Array<Integer>]
      #
      # @raise [SashimiTanpopo::NotFoundUserError]
      #
      # @see https://docs.gitlab.com/api/users/#as-a-regular-user
      def get_user_ids_from_user_names!(usernames)
        Parallel.map(usernames, in_threads: 2) do |username|
          get_user_id_from_user_name!(username)
        end
      end

      # @param mode [String] e.g. `100644`, `100755`
      #
      # @return [Boolean]
      def self.executable_mode?(mode)
        (mode.to_i(8) & 1) != 0
      end

      private

      def with_retry
        retry_count ||= 0

        yield
      rescue Gitlab::Error::MethodNotAllowed, Gitlab::Error::NotAcceptable, Gitlab::Error::Unprocessable => error
        retry_count += 1

        raise error if retry_count > MAX_RETRY_COUNT

        SashimiTanpopo.logger.warn "Error is occurred and auto retry (#{retry_count}/#{MAX_RETRY_COUNT}): #{error}"

        # 1, 2, 4, 8, 16 ...
        sleep_time = 2 ** (retry_count - 1)

        sleep sleep_time

        retry
      end

      # Whether exists branch on repository
      #
      # @param branch [String]
      #
      # @return [Boolean]
      #
      # @see https://docs.gitlab.com/api/branches/#get-single-repository-branch
      def exists_branch?(branch)
        with_retry do
          @gitlab.branch(@repository, branch)
        end
        true
      rescue Gitlab::Error::NotFound
        false
      end

      # Create branch on repository and push changes
      #
      # @param changed_files [Hash<String, { before_content: String, after_content: String, mode: String }>] key: file path, value: Hash
      #
      # @see https://docs.gitlab.com/api/commits/#create-a-commit-with-multiple-files-and-actions
      def create_branch_and_push_changes(changed_files)
        actions = changed_files.map do |file_path, changed_file|
          {
            action:           "update",
            file_path:        file_path,
            execute_filemode: self.class.executable_mode?(changed_file[:mode]),
            content:          changed_file[:after_content],
          }
        end

        with_retry do
          @gitlab.create_commit(
            @repository,
            @mr_source_branch,
            @commit_message,
            actions,
            start_branch: @mr_target_branch,
            author_email: @git_email,
            author_name:  @git_username,
          )
        end
      end

      # @return [Hash{iid: Integer, web_url: String}] Created Merge Request info
      #
      # @see https://docs.gitlab.com/api/merge_requests/#create-mr
      def create_merge_request
        params = {
          source_branch:        @mr_source_branch,
          target_branch:        @mr_target_branch,
          remove_source_branch: true,
          description:          @mr_body,
        }

        params[:labels] = @mr_labels.join(",") unless @mr_labels.empty?

        unless @mr_assignees.empty?
          params[:assignee_ids] = get_user_ids_from_user_names!(@mr_assignees)
        end

        unless @mr_reviewers.empty?
          params[:reviewer_ids] = get_user_ids_from_user_names!(@mr_reviewers)
        end

        mr_title =
          if @is_draft_mr
            "Draft: " + @mr_title
          else
            @mr_title
          end

        mr = with_retry do
          @gitlab.create_merge_request(
            @repository,
            mr_title,
            params,
          )
        end

        {
          iid:     mr["iid"],
          web_url: mr["web_url"],
        }
      end

      # @param mr_iid [Integer]
      #
      # @see https://docs.gitlab.com/api/merge_requests/#merge-a-merge-request
      def set_auto_merge(mr_iid)
        with_retry do
          @gitlab.accept_merge_request(@repository, mr_iid, auto_merge: true, should_remove_source_branch: true)
        end
      end
    end
  end
end
