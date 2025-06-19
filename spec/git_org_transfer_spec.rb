require 'git_org_transfer'
require 'octokit'

RSpec.describe 'Repository migration' do
  let(:client) { Octokit::Client.new(access_token: 'fake-token') }
  let(:source_org) { 'source-org' }
  let(:source_repo) { 'source-repo' }
  let(:target_org) { 'target-org' }
  let(:new_repo_name) { 'new-repo-name' }
  let(:full_repo_name) { "#{target_org}/#{new_repo_name}" }

  before do
    allow(Octokit::Client).to receive(:new).and_return(client)
  end

  it 'clones the repository from the source organization' do
    expect(client).to receive(:clone_repository).with(source_repo)
    client.clone_repository(source_repo)
  end

  it 'creates a new repository in the target organization' do
    expect(client).to receive(:create_repository).with(
      new_repo_name,
      organization: target_org,
      private: true
    ).and_return(double(full_name: full_repo_name))

    repo = client.create_repository(
      new_repo_name,
      organization: target_org,
      private: true
    )
    expect(repo.full_name).to eq(full_repo_name)
  end

  it 'pushes the cloned repository to the new remote' do
    expect(client).to receive(:push_to_new_remote).with(source_repo)
    client.push_to_new_remote(source_repo)
  end

  it 'sets the default branch to main' do
    expect(client).to receive(:rename_default_branch).with(full_repo_name, 'master', 'main')
    client.rename_default_branch(full_repo_name, 'master', 'main')
  end

  it 'checks if the repository exists in the target organization' do
    expect(client).to receive(:repository_exists?).with(full_repo_name)
    client.repository_exists?(full_repo_name)
  end

  it 'returns the new repository name with prepend_prefix as true' do
    git_org_transfer = GitOrgTransfer.new(source_org, target_org, true)
    expect(git_org_transfer.new_repo_name(source_repo)).to eq("#{target_org}-#{source_repo.split('-').last}")
  end

  it 'returns the new repository name with prepend_prefix as false' do
    git_org_transfer = GitOrgTransfer.new(source_org, target_org, false)
    expect(git_org_transfer.new_repo_name(source_repo)).to eq(source_repo)
  end
end
