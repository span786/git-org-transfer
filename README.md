# git-org-transfer

A Ruby utility to clone a GitHub repository and push it to a new organization using the [octokit](https://github.com/octokit/octokit.rb) gem.

## Features

- Clone a repository from a source organization or user
- Create a new private repository in the target organization
- Push all branches and tags to the new repository
- Set the default branch (e.g., `main`)

## Prerequisites

- Ruby (3.x recommended)
- [octokit](https://github.com/octokit/octokit.rb) gem
- Git installed and available in your PATH
- A GitHub personal access token with `repo` and `admin:org` permissions

## Installation

Install dependencies:

```sh
gem install octokit
```

Or use Bundler:

```sh
bundle install
```

## Usage

1. **Clone the source repository:**

   ```sh
   git clone https://github.com/source-org/source-repo.git
   cd source-repo
   ```

2. **Create a new repository in the target organization:**

   ```ruby
   require 'octokit'

   client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
   repo = client.create_repository(
     'new-repo-name',
     organization: 'target-org',
     private: true
   )
   puts "Created: #{repo.full_name}"
   ```

3. **Change the remote and push all branches and tags:**

   ```sh
   git remote add upstream https://github.com/target-org/new-repo-name.git
   git push --all upstream
   git push --tags upstream
   ```

4. **Rename `master` to `main` as the default branch:**

   ```ruby
   client.rename_branch('target-org/new-repo-name', 'master', 'main')
   ```

## Testing

Run RSpec tests:

```sh
rspec spec/git_org_transfer_spec.rb
```

## Notes

- Ensure your `GITHUB_TOKEN` environment variable is set before running the Ruby scripts.
- The script assumes the `main` branch exists in your repository.
- You must have admin rights in the target organization to create repositories.

##