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
      api_endpoint:     api_endpoint,
      access_token:     access_token,
      mr_title:         mr_title,
      mr_body:          mr_body,
      mr_source_branch: mr_source_branch,
      mr_target_branch: mr_target_branch,
      mr_assignees:     mr_assignees,
      mr_reviewers:     mr_reviewers,
      mr_labels:        mr_labels,
      is_draft_mr:      is_draft_mr,
      is_auto_merge:    is_auto_merge,
    )
  end

  include_context "uses temp dir"

  let(:recipe_paths) { [] }
  let(:target_dir) { temp_dir }
  let(:params) { {} }
  let(:dry_run) { false }
  let(:is_colored) { true }

  let(:git_username)       { "test" }
  let(:git_email)          { "test@example.com" }
  let(:commit_message)     { "Update files" }
  let(:repository)         { "example/example" }
  let(:escaped_repository) { repository.gsub("/", "%2F") }
  let(:api_endpoint)       { "https://gitlab.example.com/api/v4" }
  let(:access_token)       { "DUMMY" }
  let(:mr_title)           { "MR title" }
  let(:mr_body)            { "MR body" }
  let(:mr_source_branch)   { "test" }
  let(:mr_target_branch)   { "main" }
  let(:mr_assignees)       { %w(sue445) }
  let(:mr_reviewers)       { %w(sue445-test) }
  let(:mr_labels)          { %w(sashimi-tanpopo) }
  let(:is_draft_mr)        { false }
  let(:is_auto_merge)      { true }

  let(:request_headers) do
    {
      "Accept" => "application/json",
      "Content-Type" => "application/x-www-form-urlencoded",
      "Private-Token" => access_token,
    }
  end

  let(:response_headers) do
    {
      "Content-Type" => "application/json",
    }
  end

  describe "#perform" do
    subject { provider.perform }

    before do
      FileUtils.cp(fixtures_dir.join("test.txt"), temp_dir)

      create_commit_payload = {
        actions: [
          {
            action: "update",
            file_path: "test.txt",
            execute_filemode: "false",
            content: "Hi, sue445!\n",
          }
        ],
        author_email: git_email,
        author_name: git_username,
        branch: mr_source_branch,
        commit_message: commit_message,
        start_branch: mr_target_branch,
      }

      stub_request(:post, "#{api_endpoint}/projects/#{escaped_repository}/repository/commits").
        with(headers: request_headers, body: create_commit_payload).
        to_return(status: 200, headers: response_headers, body: fixture("gitlab_create_commit.json"))

      allow(provider).to receive(:get_user_id_from_user_name).with("sue445") { 1 }
      allow(provider).to receive(:get_user_id_from_user_name).with("sue445-test") { 2 }

      set_auto_merge_payload = {
        auto_merge: true,
        should_remove_source_branch: true,
      }

      stub_request(:put, "#{api_endpoint}/projects/#{escaped_repository}/merge_requests/1/merge").
        with(headers: request_headers, body: set_auto_merge_payload).
        to_return(status: 200, headers: response_headers, body: fixture("gitlab_merge_merge_request.json"))
    end

    let(:recipe_paths) do
      [
        fixtures_dir.join("recipe.rb").to_s,
      ]
    end

    let(:params) { { name: "sue445"} }

    context "branch isn't exists" do
      before do
        stub_request(:get, "#{api_endpoint}/projects/#{escaped_repository}/repository/branches/#{mr_source_branch}").
          with(headers: request_headers).
          to_return(status: 404, headers: response_headers, body: "{}")
      end

      context "create non-draft MR" do
        let(:is_draft_mr) { false }

        before do
          create_mr_payload = {
            title: mr_title,
            source_branch: mr_source_branch,
            target_branch: mr_target_branch,
            remove_source_branch: true,
            description: mr_body,
            labels: mr_labels.join(","),
            assignee_ids: [1],
            reviewer_ids: [2],
          }

          stub_request(:post, "#{api_endpoint}/projects/#{escaped_repository}/merge_requests").
            with(headers: request_headers, body: create_mr_payload).
            to_return(status: 200, headers: response_headers, body: fixture("gitlab_create_merge_request.json"))
        end

        it "file is not updated and create Merge Request" do
          mr_url = subject

          expect(mr_url).to eq "http://gitlab.example.com/my-group/my-project/merge_requests/1"

          test_txt = File.read(temp_dir_path.join("test.txt"))
          expect(test_txt).to eq "Hi, name!\n"
        end
      end

      context "create draft MR" do
        let(:is_draft_mr) { true }

        before do
          create_mr_payload = {
            title: "Draft: #{mr_title}",
            source_branch: mr_source_branch,
            target_branch: mr_target_branch,
            remove_source_branch: true,
            description: mr_body,
            labels: mr_labels.join(","),
            assignee_ids: [1],
            reviewer_ids: [2],
          }

          stub_request(:post, "#{api_endpoint}/projects/#{escaped_repository}/merge_requests").
            with(headers: request_headers, body: create_mr_payload).
            to_return(status: 200, headers: response_headers, body: fixture("gitlab_create_merge_request.json"))
        end

        it "file is not updated and create Merge Request" do
          mr_url = subject

          expect(mr_url).to eq "http://gitlab.example.com/my-group/my-project/merge_requests/1"

          test_txt = File.read(temp_dir_path.join("test.txt"))
          expect(test_txt).to eq "Hi, name!\n"
        end
      end
    end

    context "branch is exists" do
      before do
        stub_request(:get, "#{api_endpoint}/projects/#{escaped_repository}/repository/branches/#{mr_source_branch}").
          with(headers: request_headers).
          to_return(status: 200, headers: response_headers, body: fixture("gitlab_get_branch.json"))
      end

      it "file is not updated and not created PullRequest" do
        mr_url = subject

        expect(mr_url).to eq nil

        test_txt = File.read(temp_dir_path.join("test.txt"))
        expect(test_txt).to eq "Hi, name!\n"
      end
    end
  end

  describe "#get_user_id_from_user_name" do
    subject { provider.get_user_id_from_user_name(username) }

    let(:username) { "john_smith" }

    context "user is exists" do
      before do
        stub_request(:get, "#{api_endpoint}/users?username=#{username}").
          with(headers: request_headers).
          to_return(status: 200, headers: response_headers, body: fixture("gitlab_get_users_1.json"))
      end

      it { should eq 1 }
    end

    context "user is not exists" do
      before do
        stub_request(:get, "#{api_endpoint}/users?username=#{username}").
          with(headers: request_headers).
          to_return(status: 200, headers: response_headers, body: "[]")
      end

      it { should eq nil }
    end
  end

  describe "#get_user_id_from_user_name!" do
    subject { provider.get_user_id_from_user_name!(username) }

    let(:username) { "john_smith" }

    context "user is exists" do
      before do
        stub_request(:get, "#{api_endpoint}/users?username=#{username}").
          with(headers: request_headers).
          to_return(status: 200, headers: response_headers, body: fixture("gitlab_get_user.json"))
      end

      it { should eq 1 }
    end

    context "user is not exists" do
      before do
        stub_request(:get, "#{api_endpoint}/users?username=#{username}").
          with(headers: request_headers).
          to_return(status: 200, headers: response_headers, body: "[]")
      end

      it { expect { subject }.to raise_error SashimiTanpopo::NotFoundUserError }
    end
  end

  describe "#get_user_id_from_user_names!" do
    subject { provider.get_user_ids_from_user_names!(usernames) }

    let(:username) { "john_smith" }
    let(:usernames) { [username] }

    context "users are exists" do
      before do
        stub_request(:get, "#{api_endpoint}/users?username=#{username}").
          with(headers: request_headers).
          to_return(status: 200, headers: response_headers, body: fixture("gitlab_get_user.json"))
      end

      it { should eq [1] }
    end

    context "users are not exists" do
      before do
        stub_request(:get, "#{api_endpoint}/users?username=#{username}").
          with(headers: request_headers).
          to_return(status: 200, headers: response_headers, body: "[]")
      end

      it { expect { subject }.to raise_error SashimiTanpopo::NotFoundUserError }
    end
  end

  describe ".executable_mode?" do
    subject { SashimiTanpopo::Provider::GitLab.executable_mode?(mode) }

    context "with executable mode" do
      let(:mode) { "100755" }

      it { should eq true }
    end

    context "with non executable mode" do
      let(:mode) { "100644" }

      it { should eq false }
    end
  end
end
