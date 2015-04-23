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
  require 'ridley'
rescue LoadError => e
  raise "Missing gem or lib #{e}"
end

module Comrad
  # uploads / removes objects that changed from the chef server
  class Chef
    def initialize(config, changes)
      @config = config
      @changes = changes
      @slack = Comrad::Slack.new(config)
    end

    # builds a string of what the action is / would be depending on dry run or not
    def action_string(action, trailing_text)
      string = @config['flags']['dryrun'] ? " - I would #{action} " : " - #{action.capitalize.chomp('e')}ing "
      string + trailing_text
    end

    # a really horrible method to build knife commands based on item / action / item type (cookbook/role/environment/data_bag)
    def build_knife_cmd(type, action, item1, item2 = nil)
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
    def excute_knife_cmd(cmd)
      if @config['flags']['dryrun']
        @slack.slack_put("    - I would be running #{cmd}")
      else
        @slack.slack_put('    - Non-dry mode is not implemented.  Doing nothing')
      end
    end

    # main method of the class.  Iterates over the changes passed in and kicks off actions / slack messaging
    def take_actions
      @changes.each_pair do |type, name|
        next if name.empty?
        case
        when type.match(/^['environments|roles']/)
          name.each_pair do |item, action|
            @slack.slack_put(action_string(action, "#{item}"))
            excute_knife_cmd(build_knife_cmd(type, action, item))
          end
        when type == 'cookbooks'
          name.each_pair do |item, action|
            @slack.slack_put(action_string(action, "#{item}"))
            excute_knife_cmd(build_knife_cmd(type, action, item))
          end
        when type == 'data_bags'
          name.each_pair do |bag, item|
            item.each_pair do |bag_item_name, action|
              @slack.slack_put(action_string(action, "#{bag}::#{bag_item_name} data bag item"))
              excute_knife_cmd(build_knife_cmd(type, action, bag, bag_item_name))
            end
          end
        end
      end
    end

    # called by application to perform actions
    def run
      @slack.slack_put("Comrad action for chef repo build # #{ENV['BUILD_NUMBER']}:")
      take_actions
    end
  end # Chef class
end # Comrad Module
