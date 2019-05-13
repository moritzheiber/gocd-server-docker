require 'serverspec'
require 'docker'
require 'docker/compose'
require 'rspec/wait'
require 'bcrypt'

set :backend, :docker
set :os, family: :alpine

# Helpers
module Helpers
  def os_version
    command('cat /etc/os-release').stdout
  end

  def compose
    @compose ||= Docker::Compose.new
  end

  def container_id(image_name)
    compose.ps.where { |c| !c.nil? && c.image == image_name }.first.id
  end

  def parse_passwd(value)
    value.split(':')[1]
  end

  def passwd_eq?(enc, token)
    enc == token
  end
end

RSpec.configure do |c|
  c.include Helpers
  c.extend Helpers
  c.wait_timeout = 60
end
