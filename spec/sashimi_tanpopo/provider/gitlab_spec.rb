# frozen_string_literal: true

RSpec.describe SashimiTanpopo::Provider::GitLab do
  let(:provider) do
    SashimiTanpopo::Provider::GitLab.new(
      recipe_paths:     recipe_paths,
      target_dir:       target_dir,
      params:           params,
      dry_run:          dry_run,
      is_colored:       is_colored,
      git_username:     git_username,
      git_email:        git_email,
      commit_message:   commit_message,
      repository:       repository,
      access_token:     access_token,
      mr_title:         mr_title,
      mr_body:          mr_body,
      mr_source_branch: mr_source_branch,
      mr_target_branch: mr_target_branch,
      mr_assignees:     mr_assignees,
      mr_reviewers:     mr_reviewers,
      mr_labels:        mr_labels,
      is_draft_mr:      is_draft_mr,
    )
  end

  include_context "uses temp dir"

  let(:recipe_paths) { [] }
  let(:target_dir) { temp_dir }
  let(:params) { {} }
  let(:dry_run) { false }
  let(:is_colored) { true }

  let(:git_username)     { nil }
  let(:git_email)        { nil }
  let(:commit_message)   { "Update files" }
  let(:repository)       { "example/example" }
  let(:access_token)     { "DUMMY" }
  let(:mr_title)         { "MR title" }
  let(:mr_body)          { "MR body" }
  let(:mr_source_branch) { "test" }
  let(:mr_target_branch) { "main" }
  let(:mr_assignees)     { %w(sue445) }
  let(:mr_reviewers)     { %w(sue445-test) }
  let(:mr_labels)        { %w(sashimi-tanpopo) }
  let(:is_draft_mr)      { false }

  describe "#perform" do
    subject { provider.perform }

  end
end
