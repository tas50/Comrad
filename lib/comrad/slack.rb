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

require 'rest-client'
require 'json'

# base module
module Comrad
  # send notifications to slack
  class Slack
    def initialize(config)
      @config = config
      @url = config['slack']['webhook_url']
    end

    def slack_put(text)
      puts text
      post(text) unless @config['flags']['quiet']
    end

    def post(text)
      RestClient.post @url, create_message(text).to_json
    end

    def create_message(text)
      message = {}
      message['text'] = text
      message
    end
  end
end
