# frozen_string_literal: true
#
# lib/git_org_transfer.rb
#
# This script will clone repositories from the source organization,
# create new private repositories in the destination organization,
# push the cloned content, and set the default branch to 'main'.
# Usage:
# 1. Set the GITHUB_TOKEN environment variable with your GitHub personal access token.
# 2. Run the script with the source and destination organizations as arguments.
# Example:
#   GITHUB_TOKEN=your_token ruby git_repo_clone_and_transfer.rb source_org destination_org

require './lib/git_org_transfer'
require 'fileutils'

# Initialize the GitOrgTransfer class with source and destination organizations
# Replace 'voxpupuli' with your source organization and 'puppetlabs' with your destination organization
# Ensure you have the necessary permissions to create repositories in the destination organization
# and that the GITHUB_TOKEN environment variable is set with a valid token.
if ENV['GITHUB_TOKEN'].nil? || ENV['GITHUB_TOKEN'].empty?
  puts "Please set the GITHUB_TOKEN environment variable with your GitHub personal access token."
  exit 1
end

# Create the workspace directory if it doesn't exist
# This is where the repositories will be cloned
unless Dir.exist?(GitOrgTransfer::WORKSPACE)
  puts "Creating workspace directory at #{GitOrgTransfer::WORKSPACE}"
  begin
    FileUtils.mkdir_p(GitOrgTransfer::WORKSPACE)
  rescue StandardError => e
    puts "Failed to create workspace directory: #{e.message}"
    exit 1
  end
end

# Get source and destination organizations from command line arguments or use defaults
source_org = ARGV[0] || 'source-org' # Replace with your source organization
destination_org = ARGV[1] || 'destination-org' # Replace with your destination organization

# List of repositories to transfer
# You can modify this list to include the repositories you want to transfer
repos = [
  'repo-name-1',
  'repo-name-2',
  'repo-name-3',
  # Add more repositories as needed
]

# Initialize the GitOrgTransfer instance
# Set prepend_prefix to false if you don't want the destination organization name prefixed to the new repository name
# Set it to true if you want the new repository name to be prefixed with the destination organization name
# This is useful if you want to maintain a consistent naming convention across organizations
prepend_prefix = true # Change to false if you don't want the prefix
git_org_transfer = GitOrgTransfer.new(source_org, destination_org, prepend_prefix)
repo_count = repos.size
repos.each do |repo|
  new_repo_name = git_org_transfer.new_repo_name(repo)
  begin
    if git_org_transfer.repository_exists?(new_repo_name)
      puts "Repository '#{new_repo_name}' exists in '#{destination_org}'."
      next
    else
      repo_count -= 1
      puts "Repository '#{new_repo_name}' does not exist in '#{destination_org}', creating it..."

      puts "\nTransferring repository '#{repo}' from '#{source_org}' to '#{destination_org}'..."
      puts "\n1. Cloning repository '#{repo}' from '#{source_org}'...\n"
      git_org_transfer.clone_repository(repo)
      puts "\n2. Creating new private repository '#{new_repo_name}' in '#{destination_org}'...\n"
      git_org_transfer.create_repo(repo)
      puts "\n3. Pushing repository '#{repo}' to '#{destination_org}'...\n"
      git_org_transfer.push_to_new_remote(repo)
      puts "\n4. Renaming default branch to 'main'...\n"
      git_org_transfer.rename_default_branch(repo)
      puts "\nRepository '#{repo}' transferred to '#{destination_org}' and set to private with 'main' as the default branch.\n\n"
    end
  rescue Octokit::Error => e
    puts "An error occurred: #{e.message}"
    exit 1
  rescue Exception => e
    puts "An unexpected error occurred: #{e.message}"
    exit 1
  end
end
puts "\n#{repo_count} repositories exist in '#{destination_org}'."
puts "#{repos.size - repo_count} repositories have been successfully transferred from '#{source_org}' to '#{destination_org}'."
puts "All repositories have been processed."
