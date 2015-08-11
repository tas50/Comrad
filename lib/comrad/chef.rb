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

module Comrad
  # uploads / removes objects that changed from the chef server
  class Chef
    # Given an +item+ of +item_class+, return a knife command that performs +action+
    def self::knife_command(item_class, item, action)
      item_path = {
        cookbooks: item,
        data_bags: "data_bags/#{item}",
        environments: "environments/#{item}",
        roles: "roles/#{item}"
      }
      # Special case: if we're deleting a data_bag, we want
      # "bag_name item_name" without the '.json' rather than the path to the item.
      item_path[:data_bags] = item.split('/').join(' ').chomp('.json') if action == 'delete'

      knife_action = { delete: 'delete', update: 'from file' }
      # Special case: we call 'upload' instead of 'from file' for updated cookbooks
      knife_action[:update] = 'upload' if item_class == 'cookbooks'

      'knife %s %s %s' % [ # rubocop:disable FormatString
        item_class.chomp('s'), # cookbook, data_bag, environment, role
        knife_action[action.to_sym], # 'upload', 'delete' or 'from file'
        item_path[item_class.to_sym] # cookbookname, environments/foo.json, 'dbag bagitem', etc.
      ]
    end

    # handle the actual shell out
    def self::shell_out(cmd)
      require 'open3'
      puts "Running #{cmd}..."
      Open3.popen3(cmd) do |_stdin, _stdout, stderr, thread|
        unless thread.value.success?
          puts 'Failed to run the knife command with the following error:'.to_red
          puts stderr.read
        end
      end
    end

    # determine if we should shell out or print and then do it
    def self::execute_knife_cmd(cmd)
      # dry mode will just show what we would do
      if Config.config['flags']['dryrun']
        puts "I would be running '#{cmd}'"
      # are we in scary mode or not running a delete command
      elsif Config.config['flags']['scary'] || !cmd.include?('delete')
        shell_out(cmd)
      else # we're trying to delete something w/o scary mode enabled
        puts "#{cmd} skipped. Enable scary-mode to allow deletes."
      end
    end

    # perform the appropriate knife action for each item in the +changeset+
    def self::process_changes
      Changeset.changes.each_pair do |item_class, action_pairs|
        next if action_pairs.empty?
        action_pairs.each_pair do |item, action|
          execute_knife_cmd(knife_command(item_class, item, action))
        end
      end
    end
  end # Chef class
end # Comrad Module
