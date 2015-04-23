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

require 'slack/post'

# base module
module Comrad
  # send notifications to slack
  class Notifier

    def self::notify(changeset)
      unless Config.config['flags']['quiet']
        self.configure unless @configured
        Slack::Post.post_with_attachments "Comrad action for chef repo build # #{ENV['BUILD_NUMBER']}", 
          self.format_attachment(changeset)
      end

    end

    private

    def self::configure
      Slack::Post.configure(
        webhook_url: Config.config['slack']['webhook_url'],
        username: 'comrad',
        channel: Config.config['slack']['channel']
      )
      @configured = true
    end 

    def self::format_attachment(changeset)
      attach = {
        fallback: "",
        color: "#36a64f",
        fields: []
      }

      changeset.each_pair do |type, name|
        next if name.empty?
        case
        when type.match(/^['environments|roles|cookbooks']/)
          v = ""
          name.each_pair do |item, action|
            v << "#{action} #{item}\n"
          end
        when type == 'data_bags'
          v = ""
          name.each_pair do |bag, item|
            item.each_pair do |bag_item_name, action|
              v << "#{action} #{bag} #{bag_item_name}\n"
            end
          end
        end

        attach[:fallback] << "#{type}:\n#{v}"
        attach[:fields] << { title: type, value: v, short: false }
      end

      [attach]
    end

  end
end
