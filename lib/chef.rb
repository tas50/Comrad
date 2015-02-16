# encoding: UTF-8
#
# Author:: Tim Smith (<tim@cozy.co>)
# Copyright:: Copyright (c) 2014 Tim Smith
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
    end

    # interfact with the chef server
    def run
      @changes.each_pair do |type, name|
        next if name.empty?
        case
        when type.to_s.match(/^['environments|roles|cookbooks']/)
          name.each_pair do |item, action|
            puts "I'm going to #{action} #{item}"
          end
        when type.to_s.match(/^['data_bags']/)
          name.each_pair do |bag, item|
            puts "In the data bag #{bag} I will:"
            item.each_pair do |name, action|
              puts "  - #{action} #{name}"
            end
          end
        end
      end
    end
  end
end
