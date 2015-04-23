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

begin
  require 'json'
  require 'rest_client'
  require 'uri'
rescue LoadError => e
  raise "Missing gem or lib #{e}"
end

module Comrad
  # interacts with jenkins API to determine changes files
  # parses changed files to determine relevant files that will
  # need to be uploaded to chef server
  class Change
    attr_accessor :changes
    def initialize(config)
      @config = config
      @protocol = URI(@config['jenkins']['url']).scheme
      @jenkins_host = URI(@config['jenkins']['url']).host
      @username = @config['jenkins']['username']
      @password = @config['jenkins']['password']
      @job_name = @config['jenkins']['job_name']
      @jenkins_workspace_path = @config['jenkins']['workspace_dir']
      @build_num = ENV['BUILD_NUMBER']

      @build_data = query_build_data
      @changes = create_change_hash(changed_files_array)
    end

    # fetch build data using Jenkins API
    def query_build_data
      conn = RestClient::Resource.new("#{@protocol}://#{@jenkins_host}/job/#{@job_name}/#{@build_num}/api/json?", @username, @password)
      JSON.parse(conn.get)
    end

    # parse jenkins build data to determine unique list of all files that have changed accross multiple commits
    def changed_files_array
      changed_files = []

      @build_data['changeSet']['items'].each do |change|
        changed_files.concat(change['affectedPaths'])
      end

      changed_files.uniq
    end

    # create the empty hash that stores the changed objects
    def empty_chef_object_hash
      objects = {}
      objects['environments'] = {}
      objects['roles'] = {}
      objects['data_bags'] = {}
      objects['cookbooks'] = {}

      objects
    end

    # return an action based on the status of the object in the workspace
    def action(file)
      ::File.exist?(::File.join(@jenkins_workspace_path, file)) ? 'update' : 'delete'
    end

    def print
    end

    # takes an array of files that have changes and returns hash of chef objects and an action to take on the object
    def create_change_hash(files_array)
      objects = empty_chef_object_hash
      files_array.each do |file|
        case
        when file.match(/^[cookbook|roles|environments]/)
          split_file = file.split('/')
          objects[split_file[0]][split_file[1]] = action(split_file[0..1].join('/'))
        when file.match(/^data_bags/)
          split_file = file.split('/')
          objects[split_file[0]][split_file[1]] = {} unless objects[split_file[0]].key?(split_file[1])
          objects[split_file[0]][split_file[1]][split_file[2]] = action(split_file[0..2].join('/'))
        end
      end
      objects
    end
  end
end
