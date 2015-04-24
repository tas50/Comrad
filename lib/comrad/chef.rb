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
    # builds a string of what the action is / would be depending on dry run or not
    def self::action_string(action, trailing_text)
      string = Config.config['flags']['dryrun'] ? " - I would #{action} " : " - #{action.capitalize.chomp('e')}ing "
      string + trailing_text
    end

    def self::knife_command(item_class, item, action)
      item_class_singular = item_class.chomp('s')  # eg cookbooks > cookbook

      item_path = {
        cookbooks: item,
        data_bags: "data_bags/#{item}",
        environments: "environments/#{item}",
        roles: "roles/#{item}"
      }
      item_path[:data_bags] = item.split('/').join(' ') if action == 'delete' # special case

      knife_action = {
        delete: 'delete',
        update: 'from file'
      }
      knife_action[:update] = 'upload' if item_class == 'cookbooks' # special case

      "knife #{item_class_singular} #{knife_action[action.to_sym]} #{item_path[item_class.to_sym]}"
    end

    # run the provided knife command
    def self::excute_knife_cmd(cmd)
      if Config.config['flags']['dryrun']
        puts "I would be running '#{cmd}'"
      else
        puts "Live mode is not implemented. Not performing '#{cmd}'"
      end
    end

    # perform the appropriate knife action for each item in the +changeset+
    def self::process_changes(changeset)
      changeset.each_pair do |item_class, action_pairs|
        next if action_pairs.empty?
        action_pairs.each_pair do |item, action|
          excute_knife_cmd(knife_command(item_class, item, action))
        end
      end
    end
  end # Chef class
end # Comrad Module
