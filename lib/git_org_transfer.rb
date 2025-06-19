# frozen_string_literal: true
#
# lib/git_org_transfer.rb
require 'octokit'

# This class handles the transfer of repositories from one GitHub organization to another
# It clones repositories from the source organization, creates new private repositories in the destination organization,
# pushes the cloned content, and sets the default branch to 'main'.
# Usage:
# 1. Set the GITHUB_TOKEN environment variable with your GitHub personal access token.
# 2. Initialize the class with source and destination organizations.
# Example:
#   git_org_transfer = GitOrgTransfer.new('source_org', 'destination_org')
#   git_org_transfer.clone_repository('repo_name')
#   git_org_transfer.create_repo('repo_name')
#   git_org_transfer.push_to_new_remote('repo_name')
#   git_org_transfer.rename_default_branch('repo_name')
#
class GitOrgTransfer
  # Define the workspace where the repositories will be cloned
  # This should be a directory where you have write permissions
  WORKSPACE = File.expand_path('~/Documents/workspace')

  # Initialize the GitOrgTransfer class with source and destination organizations
  #
  # @param source_org [String] The source GitHub organization name
  # @param destination_org [String] The destination GitHub organization name
  # @param prepend_prefix [Boolean] Whether to prepend the destination organization name to the new repository name
  #   Defaults to true, which means the new repository name will be prefixed with the destination organization name.
  #   If false, the new repository name will be the same as the source repository name without any prefix.
  def initialize(source_org, destination_org, prepend_prefix=true)
    @client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
    @source_org = source_org
    @destination_org = destination_org
    @prepend_prefix = prepend_prefix
  end

  # Clone the repository to the local machine
  # This step assumes you have git installed and configured
  def clone_repository(repo)
    Dir.chdir(source_org_folder_path) do
      system("git clone https://github.com/#{@source_org}/#{repo}.git")
    end
  end

  # After cloning, create a new repository in the target organization
  def create_repo(repo)
    @client.create_repository(
      new_repo_name(repo),
      organization: @destination_org,
      description: "Private repo of https://github.com/#{@source_org}/#{repo}",
      private: true # or false if you want it public
    )
  end

  # Push the cloned repository to the new remote in the target organization
  # # @param repo [String] The name of the repository to push
  # This method assumes that the repository has been cloned and is available in the local workspace
  def push_to_new_remote(repo)
    source_repo_path = "#{WORKSPACE}/#{@source_org}/#{repo}"
    Dir.chdir(source_repo_path) do
      # Set the new remote to the target organization
      system("git remote add upstream git@github.com:#{@destination_org}/#{new_repo_name(repo)}.git")
      # Push all branches and tags to the new remote
      system("git push --all upstream")
      system("git push --tags upstream")
    end
  end

  # Rename the default branch to 'main'
  # This method assumes that the repository has been pushed to the new remote
  def rename_default_branch(repo)
    begin
      @client.rename_branch("#{@destination_org}/#{new_repo_name(repo)}", 'master', 'main')
    rescue Octokit::Error => e
      puts "Failed to set the default branch: #{e.message}"
      exit 1
    end
  end

  # Check if the repository already exists in the destination organization
  # This method is useful to avoid creating duplicates
  # @param repo [String] The name of the repository to check
  # @return [Boolean] true if the repository exists, false otherwise
  def repository_exists?(repo)
    @client.repository?("#{@destination_org}/#{new_repo_name(repo)}")
  end

  # Generate a new repository name based on the source repository name
  # This method can be customized to change the naming convention as needed
  def new_repo_name(repo_name)
    @prepend_prefix ? "#{@destination_org}-#{repo_name.split('-').last}" : repo_name
  end

  private

  # Get the path to the source organization folder in the workspace
  def source_org_folder_path
    "#{WORKSPACE}/#{@source_org}"
  end

  # Get the full path to the source repository in the workspace
  # This method is used to locate the cloned repository for pushing to the new remote
  # @param repo_name [String] The name of the repository
  # @return [String] The full path to the source repository
  def source_repo_path(repo_name)
    "#{source_org_folder_path}/#{repo_name}"
  end
end
