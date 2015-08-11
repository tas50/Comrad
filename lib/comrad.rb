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
require 'core_ext/string'

require 'comrad/config'
require 'comrad/changeset'
require 'comrad/chef'
require 'comrad/notifier'

# Your rad comrade - Sync changes from git to Chef Server via Jenkins
module Comrad
  module_function

  # Evaluate the current build for chef object changes,
  # use knife to upload changed objects to the Chef server,
  # send a notification to slack.
  def self::run
    if Config.config['flags']['print_config']
      'Current config file / CLI flag values'.marquee
      Config.print
      exit
    end

    if Changeset.empty?
      'No objects to test. Exiting'.to_green
      exit
    end

    'The following chef objects will be changed'.marquee
    puts Changeset.changes.to_yaml.gsub("---\n", '')

    'Making Chef Changes'.marquee
    Chef.process_changes

    Notifier.notify_changes
  end
end
