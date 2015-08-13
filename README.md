Comrad
======
[![Build Status](https://travis-ci.org/tas50/Comrad.svg)](https://travis-ci.org/tas50/Comrad)
[![Gem Version](https://badge.fury.io/rb/comrad.svg)](http://badge.fury.io/rb/comrad)

Comrad prevents human error, by automatically syncing changes on the master branch of your chef repo to your chef server. You eliminate the chance that someone uploads an outdated file or misses an upload, by automating the process.  Comrad runs as a Jenkins job allowing you to trigger the job after acceptance tests.  All changes are logged in the Jenkins job history and optionally log to Slack using Slack webhooks.

## Usage
Comrad has several command line options and also a YAML config file.

Command line options:
```
    -p, --print                      Print the config options that would be used, and then exit
    -c, --config comrad.yml          Path to config file (defaults to /etc/comrad.yml)
    -q, --quiet                      Don't post actions to Slack
    -d, --dry-run                    Print what you would do, but don't actually do it
    -s, --scary-mode                 Enable the deletion of objects if they've been removed from git
    -h, --help                       Displays Help
```

Example YAML config:
```
  ---
slack:
  webhook_url: 'https://hooks.slack.com/services/123/123/123
  channel: '#ops-channel'
jenkins:
  workspace_dir: '/var/jenkins/workspaces/myjob/'
  url: 'http://jenkins.int.myco.co/'
  username: 'jenkins-api-user'
  password: 'jenkins-api-password'
  job_name: 'my-jenkins-job'
chef:
  pem_path: '/home/jenkins/.chef/jenkins.pem'
  client_name: 'jenkins'
  server_url: https://chef.int.myco.co
```
