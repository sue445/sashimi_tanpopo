# frozen_string_literal: true

RSpec.describe SashimiTanpopo::Provider::GitHub do
  let(:provider) do
    SashimiTanpopo::Provider::GitHub.new(
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
      pr_title:         pr_title,
      pr_body:          pr_body,
      pr_source_branch: pr_source_branch,
      pr_target_branch: pr_target_branch,
      pr_assignees:     pr_assignees,
      pr_reviewers:     pr_reviewers,
      pr_labels:        pr_labels,
      is_draft_pr:      is_draft_pr,
    )
  end

  include_context "uses temp dir"

  let(:recipe_paths) { [] }
  let(:target_dir) { temp_dir }
  let(:params) { {} }
  let(:dry_run) { false }
  let(:is_colored) { true }

  let(:git_username)     { "test" }
  let(:git_email)        { "test@example.com" }
  let(:commit_message)   { "Update files" }
  let(:repository)       { "example/example" }
  let(:access_token)     { "DUMMY" }
  let(:pr_title)         { "PR title" }
  let(:pr_body)          { "PR body" }
  let(:pr_source_branch) { "test" }
  let(:pr_target_branch) { "main" }
  let(:pr_assignees)     { %w(sue445) }
  let(:pr_reviewers)     { %w(sue445-test) }
  let(:pr_labels)        { %w(sashimi-tanpopo) }
  let(:is_draft_pr)      { false }

  describe "#perform" do
    subject { provider.perform }

    before do
      FileUtils.cp(fixtures_dir.join("test.txt"), temp_dir)
    end

    let(:recipe_paths) do
      [
        fixtures_dir.join("recipe.rb").to_s,
      ]
    end

    let(:params) { { name: "sue445"} }

    let(:request_headers) do
      {
        "Accept" => "application/vnd.github.v3+json",
        "Authorization" => "token #{access_token}",
        "Content-Type" => "application/json",
      }
    end

    let(:response_headers) do
      {
        "Content-Type" => "application/json",
      }
    end

    before do
      stub_request(:get, "https://api.github.com/repos/#{repository}/git/refs/heads/#{pr_target_branch}").
        with(headers: request_headers).
        to_return(status: 200, headers: response_headers, body: fixture("github_get_ref.json"))

      ref_json = {
        ref: "refs/heads/#{pr_source_branch}",
        sha: "aa218f56b14c9653891f9e74264a383fa43fefbd",
      }.to_json

      stub_request(:post, "https://api.github.com/repos/#{repository}/git/refs").
        with(headers: request_headers, body: ref_json).
        to_return(status: 201, headers: response_headers, body: fixture("github_create_ref.json"))

      stub_request(:get, "https://api.github.com/repos/#{repository}/commits/aa218f56b14c9653891f9e74264a383fa43fefbd").
        with(headers: request_headers).
        to_return(status: 200, headers: response_headers, body: fixture("github_get_commit.json"))

      blob_json = {
        content: "Hi, sue445!\n",
        encoding: "utf-8",
      }.to_json

      stub_request(:post, "https://api.github.com/repos/#{repository}/git/blobs").
        with(headers: request_headers, body: blob_json).
        to_return(status: 201, headers: response_headers, body: fixture("github_create_blob.json"))

      tree_json = {
        base_tree: "6dcb09b5b57875f334f61aebed695e2e4193db5e",
        tree: [
          {
            path: "test.txt",
            mode: "100644",
            type: "blob",
            sha: "3a0f86fb8db8eea7ccbb9a95f325ddbedfb25e15"
          }
        ]
      }.to_json

      stub_request(:post, "https://api.github.com/repos/#{repository}/git/trees").
        with(headers: request_headers, body: tree_json).
        to_return(status: 201, headers: response_headers, body: fixture("github_create_tree.json"))

      commit_json = {
        author: {
          name: "test",
          email:  "test@example.com",
        },
        message: "Update files",
        tree: "cd8274d15fa3ae2ab983129fb037999f264ba9a7",
        parents: [
          "aa218f56b14c9653891f9e74264a383fa43fefbd",
        ],
      }.to_json

      stub_request(:post, "https://api.github.com/repos/#{repository}/git/commits").
        with(headers: request_headers, body: commit_json).
        to_return(status: 201, headers: response_headers, body: fixture("github_create_commit.json"))

      update_ref_json = {
        sha: "7638417db6d59f3c431d3e1f261cc637155684cd",
        force: false,
      }.to_json

      stub_request(:patch, "https://api.github.com/repos/#{repository}/git/refs/heads/#{pr_source_branch}").
        with(headers: request_headers, body: update_ref_json).
        to_return(status: 200, headers: response_headers, body: fixture("github_update_ref.json"))

      create_pr_json = {
        draft: is_draft_pr,
        base: pr_target_branch,
        head: pr_source_branch,
        title: pr_title,
        body: pr_body,
      }.to_json

      stub_request(:post, "https://api.github.com/repos/#{repository}/pulls").
        with(headers: request_headers, body: create_pr_json).
        to_return(status: 201, headers: response_headers, body: fixture("github_create_pull_request.json"))

      stub_request(:post, "https://api.github.com/repos/#{repository}/issues/1347/labels").
        with(headers: request_headers, body: pr_labels.to_json).
        to_return(status: 201, headers: response_headers, body: fixture("github_add_labels.json"))

      stub_request(:post, "https://api.github.com/repos/#{repository}/issues/1347/assignees").
        with(headers: request_headers, body: { assignees: pr_assignees, }.to_json).
        to_return(status: 201, headers: response_headers, body: fixture("github_add_assignees.json"))

      stub_request(:post, "https://api.github.com/repos/#{repository}/pulls/1347/requested_reviewers").
        with(headers: request_headers, body: { reviewers: pr_reviewers, }.to_json).
        to_return(status: 201, headers: response_headers, body: fixture("github_add_reviewers.json"))
    end

    it "file is not updated and create PullRequest" do
      pr_url = subject

      expect(pr_url).to eq "https://github.com/octocat/Hello-World/pull/1347"

      test_txt = File.read(temp_dir_path.join("test.txt"))
      expect(test_txt).to eq "Hi, name!\n"
    end
  end
end
