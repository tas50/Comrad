# encoding: UTF-8
#
# Author:: Tim Smith (<tim@cozy.co>)
# Copyright:: Copyright (c) 2014 Tim Smith
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

begin
  require 'yaml'
  require 'optparse'
rescue LoadError => e
  raise "Missing gem or lib #{e}"
end

module Comrad
  # builds a single config from passed flags, yaml config, and knife.rb
  class Config
    attr_accessor :settings
    def initialize
      @flags = parse_flags
      @config_file = load_file
      @settings = merge_configs
    end

    # grabs the flags passed in via command line
    def parse_flags
      flags = { :config => '/etc/comrad.yml', :print_config => false }
      OptionParser.new do |opts|
        opts.banner = 'Usage: comrad [options]'

        opts.on('-p', '--print', 'Print the config options that will be used') do |config|
          flags[:print_config] = config
        end

        opts.on('-c', '--config comrad.yml', 'Path to config file (defaults to /etc/comrad.yml)') do |config|
          flags[:config] = config
        end

        opts.on('-h', '--help', 'Displays Help') do
          puts opts
          exit
        end
      end.parse!

      flags
    end

    # loads the comrad.yml config file from /etc/comrad.yml or the passed location
    def load_file
      config = YAML.load_file(@flags[:config])
      if config == false
        puts "ERROR: Comrad config at #{@flags[:config]} does not contain any configuration data"
        exit 1
      end
      config
    rescue Errno::ENOENT
      puts "ERROR: Cannot load Comrad config file at #{@flags[:config]}"
      exit 1
    rescue Psych::SyntaxError
      puts "ERROR: Syntax error in Comrad config file at #{@flags[:config]}"
      exit 1
    end

    # join the config file with the passed flags into a single object
    def merge_configs
      config = @config_file
      config['flags'] = {}
      @flags.each { |k, v| config['flags'][k.to_s] = v }
      config
    end

    # pretty print the config hash
    def print(hash = nil, spaces = 0)
      hash = @settings if hash.nil?
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
  end
end
