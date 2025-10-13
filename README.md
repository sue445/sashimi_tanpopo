# SashimiTanpopo :sushi: :blossom:
Change files and create patches

[![test](https://github.com/sue445/sashimi_tanpopo/actions/workflows/test.yml/badge.svg)](https://github.com/sue445/sashimi_tanpopo/actions/workflows/test.yml)

## Example
```ruby
# recipe.rb

update_file ".ruby-version" do |content|
  content.gsub!(/^[\d.]+$/, params[:ruby_version])
end

update_file "Dockerfile" do |content|
  content.gsub!(/^FROM ruby:([\d.]+)$/, %Q{FROM ruby:#{params[:ruby_version]}})
end

@ruby_minor_version = params[:ruby_version].to_f

update_file ".rubocop.yml" do |content|
  content.gsub!(/TargetRubyVersion: ([\d.]+)/, "TargetRubyVersion: #{@ruby_minor_version}")
end

update_file ".github/workflows/*.yml" do |content|
  content.gsub!(/ruby-version: "(.+)"/, %Q{ruby-version: "#{params[:ruby_version]}"})
end
```

```bash
# Update local app files using recipe.rb
$ sashimi_tanpopo local --target-dir=/path/to/app --params=ruby_version:3.4.5 /path/to/recipe.rb

# Update local app files using recipe.rb and create Pull Request
$ sashimi_tanpopo github --target-dir=/path/to/app --params=ruby_version:3.4.5 --message="Upgrade to Ruby 3.4.5" --github-repository=yourname/yourrepo \
--pr-title="Upgrade to Ruby 3.4.5" --pr-source-branch=ruby_3.4.5 --pr-target-branch=main --pr-draft recipe.rb
```

## Installation
```bash
gem install sashimi_tanpopo
```

## Usage
### sashimi_tanpopo local
Change local files using recipe files

```bash
$ sashimi_tanpopo help local

Usage:
  sashimi_tanpopo local RECIPE [RECIPE...]

Options:
  -d, [--target-dir=TARGET_DIR]                      # Target directory
                                                     # Default: /Users/sue445/workspace/github.com/sue445/sashimi_tanpopo
  -p, [--params=key:value]                           # Params passed to recipe file
      [--dry-run], [--no-dry-run], [--skip-dry-run]  # Whether to run dry run
                                                     # Default: false
      [--color], [--no-color], [--skip-color]        # Whether to colorize output
                                                     # Default: true
```

### sashimi_tanpopo github
Change local files using recipe files and create Pull Request

```bash
$ sashimi_tanpopo help github

Usage:
  sashimi_tanpopo github RECIPE [RECIPE...] --github-repository=user/repo --pr-source-branch=pr_branch --pr-target-branch=main --pr-title=PR_TITLE -m, --message=MESSAGE

Options:
  -d, [--target-dir=TARGET_DIR]                         # Target directory
                                                        # Default: /Users/sue445/workspace/github.com/sue445/sashimi_tanpopo
  -p, [--params=key:value]                              # Params passed to recipe file
      [--dry-run], [--no-dry-run], [--skip-dry-run]     # Whether to run dry run
                                                        # Default: false
      [--color], [--no-color], [--skip-color]           # Whether to colorize output
                                                        # Default: true
      [--git-user-name=GIT_USER_NAME]                   # user name for git commit. default: username of user authenticated with token
      [--git-email=GIT_EMAIL]                           # email for git commit. default: <git_user_name>@users.noreply.<github_host>
  -m, --message=MESSAGE                                 # commit message
      --github-repository=user/repo                     # GitHub repository for Pull Request [$GITHUB_REPOSITORY]
      [--github-api-url=GITHUB_API_URL]                 # GitHub API endpoint. Either --github-api-url or $GITHUB_API_URL is required [$GITHUB_API_URL]
                                                        # Default: https://api.github.com
      [--github-token=GITHUB_TOKEN]                     # GitHub access token. Either --github-token or $GITHUB_TOKEN is required [$GITHUB_TOKEN]
      --pr-title=PR_TITLE                               # Pull Request title
      [--pr-body=PR_BODY]                               # Pull Request body
      --pr-source-branch=pr_branch                      # Pull Request source branch (a.k.a. head branch)
      --pr-target-branch=main                           # Pull Request target branch (a.k.a. base branch). Either --pr-target-branch or $GITHUB_REF_NAME is required [$GITHUB_REF_NAME]
      [--pr-assignees=one two three]                    # Pull Request assignees
      [--pr-reviewers=one two three]                    # Pull Request reviewers
      [--pr-labels=one two three]                       # Pull Request labels
      [--pr-draft], [--no-pr-draft], [--skip-pr-draft]  # Whether to create draft Pull Request
                                                        # Default: false
```

## Recipe file specification
See [docs/RECIPE.md](docs/RECIPE.md)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sue445/sashimi_tanpopo.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
