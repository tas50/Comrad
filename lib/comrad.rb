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

# Your rad comrade - Sync changes from git to Chef Server via Jenkins
module Comrad
  require 'core_ext/string'
  require 'comrad/config'
  require 'comrad/changeset'
  require 'comrad/chef'
  require 'comrad/notifier'

  module_function

  # run tests on each changed cookbook
  def self::run
    check_print_config

    ('No objects to test. Exiting'.to_green && exit) if Changeset.empty?

    # print objects that will be uploaded
    'The following chef objects will be changed'.marquee
    puts Changeset.changes

    'Making Chef Changes'.marquee
    Comrad::Chef.new(Config.config, Changeset.changes).run

    Notifier.notify(Changeset.changes)
  end

  private

  # check and see if the -p flag was passed and if so print the config hash
  def self::check_print_config
    if Config.config['flags']['print_config']
      'Current config file / CLI flag values'.marquee
      Config.print
      exit
    end
  end
end
