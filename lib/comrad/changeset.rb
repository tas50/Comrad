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

require 'json'
require 'rest_client'

module Comrad
  # interacts with jenkins API to determine changes files
  # parses changed files to determine relevant files that will
  # need to be uploaded to chef server
  class Changeset
    # Return a hash of all changed objects
    def self::changes
      @changes ||= create_change_hash(changed_files_array)
    end

    # True if there are no changed objects
    def self::empty?
      changes == empty_chef_object_hash
    end

    # Return a hash of all Jenkins details for this build
    def self::build_data
      @build_data ||= fetch_build_data
    end

    # fetch build data using Jenkins API
    def self::fetch_build_data
      j = Config.config['jenkins']
      url = j['url'] + '/job/' + j['job_name'] + '/' + Config.config['buildnum'] + '/api/json?'
      conn = RestClient::Resource.new(url, j['username'], j['password'])
      JSON.parse(conn.get)
    end

    # parse jenkins build data to determine unique list of all files that have changed accross multiple commits
    def self::changed_files_array
      changed_files = []
      build_data['changeSet']['items'].each do |change|
        changed_files.concat(change['affectedPaths'])
      end
      changed_files.uniq
    end

    def self::empty_chef_object_hash
      {
        'environments' => {},
        'roles' => {},
        'data_bags' => {},
        'cookbooks' => {}
      }
    end

    # return an action based on the status of the object in the workspace
    def self::action(file)
      ::File.exist?(::File.join(Config.config['jenkins']['workspace_dir'], file)) ? 'update' : 'delete'
    end

    # takes an array of files that have changes and returns hash of chef objects and an action to take on the object
    def self::create_change_hash(files_array)
      objects = empty_chef_object_hash
      files_array.each do |file|
        split_file = file.split('/')
        case
        when file.match(/^[cookbook|roles|environments]/)
          # "cookbooks"=>{"some-cookbook"=>"update"}
          objects[split_file[0]][split_file[1]] = action(split_file[0..1].join('/'))
        when file.match(/^data_bags/)
          # "data_bags"=>{"some_dbag/some_item.json"=>"update"}
          objects[split_file[0]][split_file[1..2].join('/')] = action(split_file[0..2].join('/'))
        end
      end
      objects
    end
  end
end
