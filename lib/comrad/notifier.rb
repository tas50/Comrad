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

module Comrad
  # send notifications to slack
  class Notifier
    def self::configure
      validate_config
      Slack::Post.configure(
        webhook_url: Config.config['slack']['webhook_url'],
        username: 'comrad',
        channel: Config.config['slack']['channel']
      )
      @configured = true
    end

    # Post a Slack notification containing details of the changes
    def self::notify_changes
      unless Config.config['flags']['quiet']
        configure unless @configured
        Slack::Post.post_with_attachments(
          'Comrad action for chef repo <%s|Build #%s>' % [ # rubocop:disable FormatString
            Changeset.build_data['url'],
            Changeset.build_data['number']],
          changeset_attachment)
      end
    end

    # Generate a Slack message attachment that contains changeset details
    def self::changeset_attachment
      attach = { fallback: '', color: '#36a64f', fields: [] }

      Changeset.changes.each_pair do |item_class, action_pairs|
        next if action_pairs.empty?
        text = ''
        action_pairs.each_pair do |item, action|
          text << "#{action} #{item}\n"
        end
        attach[:fallback] << "#{item_class}:\n#{text}"
        attach[:fields] << { title: item_class, value: text, short: false }
      end

      [attach]
    end

    # Ensure the slack config is present
    def self::validate_config
      unless Config.config['slack']['webhook_url'] && Config.config['slack']['channel']
        puts "\nSlack config in comrad.yml is incomplete. Cannot continue.".to_red
        exit!
      end
    end
  end
end
