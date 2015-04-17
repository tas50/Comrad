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
  # the main class for the comrad app.  gets called by the comrad bin
  class Application
    require 'config'
    require 'change'
    require 'chef'
    require 'string'

    def initialize
      @config_obj = Comrad::Config.new
      @config = @config_obj.settings
      @changes = Comrad::Change.new(@config).changes
    end

    # exit with a friendly message if nothing we test has been changed
    def check_empty_update
      objects_updated = false
      %w(cookbooks roles environments data_bags).each do |object|
        objects_updated = true unless @changes[object].empty?
      end

      ('No objects to test. Exiting'.to_green && exit) unless objects_updated
    end

    # check and see if the -p flag was passed and if so print the config hash
    def check_print_config
      if @config['flags']['print_config']
        'Current config file / CLI flag values'.marquee
        @config_obj.print_config
        exit
      end
    end

    # run tests on each changed cookbook
    def run
      # check_print_config
      ('No objects updated by this commit.  Exiting'.to_green && exit) if check_empty_update

      # print objects that will be uploaded
      'The following chef objects will be changed'.marquee
      puts @changes

      'Making Chef Changes'.marquee
      Comrad::Chef.new(@config, @changes).run
    end
  end
end
