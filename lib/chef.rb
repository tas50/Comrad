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
  class Chef < Application
    def initialize(config, changes)
      @config = config
      @changes = changes
      @slack = Comrad::Slack.new(config)
    end

    def action_string(action, trailing_text)
      string = @config['flags']['dryrun'] ? "- I would #{action} " : "- #{action.capitalize.chomp('e')}ing "
      string + trailing_text
    end

    # Perform actual actions on chef server and log to slack
    def take_actions
      @changes.each_pair do |type, name|
        next if name.empty?
        case
        when type.to_s.match(/^['environments|roles']/)
          name.each_pair do |item, action|
            @slack.slack_put(action_string(action, "#{item}"))
          end
        when type.to_s.match(/^['cookbooks']/)
          name.each_pair do |item, action|
            @slack.slack_put(action_string(action, "#{item}"))
          end
        when type.to_s.match(/^['data_bags']/)
          name.each_pair do |bag, item|
            item.each_pair do |bag_item_name, action|
              @slack.slack_put(action_string(action, "#{bag}::#{bag_item_name} data bag item"))
            end
          end
        end
      end
    end

    # called by application to perform actions
    def run
      @slack.slack_put("Comrad action for chef repo build # #{ENV['BUILD_NUM'] || 5}:")
      take_actions
    end
  end # Chef class
end # Comrad Module
