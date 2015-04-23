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

    # a really horrible method to build knife commands based on item / action / item type (cookbook/role/environment/data_bag)
    def self::build_knife_cmd(type, action, item1, item2 = nil)
      if type == 'data_bags'
        action == 'delete' ? "knife data bag delete #{item1} #{item2}" : "knife data bag from file #{item1} data_bags/#{item1}/#{item2}"
      elsif action == 'delete'
        "knife #{type.chomp('s')} delete #{item1} #{item2}"
      elsif type == 'cookbooks'
        "knife cookbook #{action == 'update' ? 'upload' : 'delete'} #{item1}"
      else
        "knife #{type.chomp('s')} from file #{type}/#{item1}"
      end
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
      changeset.each_pair do |type, name|
        next if name.empty?
        case
        when type.match(/^['environments|roles']/)
          name.each_pair do |item, action|
            excute_knife_cmd(build_knife_cmd(type, action, item))
          end
        when type == 'cookbooks'
          name.each_pair do |item, action|
            excute_knife_cmd(build_knife_cmd(type, action, item))
          end
        when type == 'data_bags'
          name.each_pair do |bag, item|
            item.each_pair do |bag_item_name, action|
              excute_knife_cmd(build_knife_cmd(type, action, bag, bag_item_name))
            end
          end
        end
      end
    end
  end # Chef class
end # Comrad Module
