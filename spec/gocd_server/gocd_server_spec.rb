require 'spec_helper'

# rubocop:disable Metrics/BlockLength, RSpec/DescribeClass
describe 'GoCD server web container', :extend_helpers do
  set :docker_container, 'gocd-server'

  # rubocop:disable Rspec/BeforeAfterAll
  before(:all) do
    compose.up('gocd-server', detached: true)
  end

  after(:all) do
    compose.kill
    compose.rm(force: true)
  end
  # rubocop:enable Rspec/BeforeAfterAll

  describe 'the operating system' do
    it 'is alpine' do
      expect(os_version).to include('alpine')
    end
  end

  describe group('gocd') do
    it { should exist }
  end

  describe user('gocd') do
    it { should exist }
    it { should have_login_shell '/bin/sh' }
    it { should have_home_directory '/gocd' }
    it { should belong_to_primary_group 'gocd' }
  end

  %w[
    /gocd/config
    /gocd/runtime
    /gocd/runtime/artifacts
    /gocd/runtime/db
  ].each do |d|
    describe file(d) do
      it { should be_directory }
      it { should be_mode 755 }
      it { should be_owned_by 'gocd' }
      it { should be_grouped_into 'gocd' }
    end
  end

  %w[
    curl
    unzip
  ].each do |p|
    describe package(p) do
      it { should_not be_installed }
    end
  end

  %w[
    bash
    openjdk8-jre
    git
    ca-certificates
  ].each do |p|
    describe package(p) do
      it { should be_installed }
    end
  end

  %w[
    /tmp/gocd.zip
    /tmp/extracted
  ].each do |file_absent|
    describe file(file_absent) do
      it { should_not exist }
    end
  end

  %w[
    /gocd/config/logback.xml
    /gocd/config/passwd_file
    /gocd/config/cruise-config.xml
  ].each do |file_present|
    describe file(file_present) do
      it { should be_file }
      it { should be_readable }
    end
  end

  describe file('/gocd/config/cruise-config.xml') do
    its(:content) { should match(/agentAutoRegisterKey="test"/) }
  end

  [8153, 8154].each do |p|
    describe "port #{p}" do
      it 'is listening with tcp' do
        wait_for(port(p)).to be_listening.with('tcp')
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength, RSpec/DescribeClass
