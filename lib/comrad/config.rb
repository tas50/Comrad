# encoding: UTF-8
#
# Author:: Tim Smith (<tim@cozy.co>)
# Copyright:: Copyright (c) 2014-2015 Tim Smith
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'yaml'
require 'optparse'

module Comrad
  # builds a single config from passed flags, yaml config, and knife.rb
  class Config

    # return the fully-evaluated configuration hash
    def self::settings
      @flags ||= self.parse_flags
      @settings ||= self.merge_configs(self.load_file(@flags[:config]), @flags)
    end

    # pretty print the config hash
    def self::print(hash=self.settings, spaces=0)
      hash.each do |k, v|
        spaces.times { print ' ' }
        print k.to_s + ': '
        if v.class == Hash
          print "\n"
          print_config(v, spaces + 2)
        else
          puts v
        end
      end
    end

    #######
    private
    #######

    # make sure the BUILD_NUMBER Jenkins variable exists.  If not force help
    def self::check_jenkins_env_variable
      if ENV['BUILD_NUMBER'].nil?
        puts "Jenkins set BUILD_NUMBER environmental variable not set. Cannot continue.\n\n"
        ARGV[0] = '-h'
      end
    end

    # grabs the flags passed in via command line
    def self::parse_flags
      self.check_jenkins_env_variable

      flags = { config: '/etc/comrad.yml', print_config: false, quiet: false }
      OptionParser.new do |opts|
        opts.banner = 'Usage: comrad [options]'

        opts.on('-p', '--print', 'Print the config options that would be used, and then exit') do |config|
          flags[:print_config] = config
        end

        opts.on('-c', '--config comrad.yml', 'Path to config file (defaults to /etc/comrad.yml)') do |config|
          flags[:config] = config
        end

        opts.on('-q', '--quiet', "Don't post actions to Slack") do |config|
          flags[:quiet] = config
        end

        opts.on('-d', '--dry-run', "Print what you would do, but don't actually do it") do |dryrun|
          flags[:dryrun] = dryrun
        end

        opts.on('-s', '--scary-mode', "Enable the deletion of objects if they've been removed from git") do |scary|
          flags[:scary] = scary
        end

        opts.on('-h', '--help', 'Displays Help') do
          puts opts
          exit
        end
      end.parse!

      flags
    end

    # loads the comrad.yml config file from /etc/comrad.yml or the passed location
    def self::load_file(file_path)
      config = YAML.load_file(file_path)
      if config == false
        puts "ERROR: Comrad config at #{@flags[:config]} does not contain any configuration data"
        exit 1
      end
      config
    rescue Errno::ENOENT
      puts "ERROR: Cannot load Comrad config file at #{file_path}"
      exit 1
    rescue Psych::SyntaxError
      puts "ERROR: Syntax error in Comrad config file at #{file_path}"
      exit 1
    end

    # join the config file with the passed flags into a single object
    def self::merge_configs(file_config, flags_config)
      config = file_config.dup
      config['flags'] = {}
      flags_config.each { |k, v| config['flags'][k.to_s] = v }
      config
    end

  end
end
