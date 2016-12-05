require 'json'
require 'tmpfile'

require "docs_doctor/version"

module DocsDoctor
  class ScriptExecutionError < StandardError
    def initialize(msg, out: , err: )
      msg << "STDOUT: #{out.inspect}"
      msg << "STDERR: #{err.inspect}"
      super msg
    end
  end
end


require 'docs_doctor/project_name_cache'
require 'docs_doctor/projects_from_database'
require 'docs_doctor/github_fetcher'
require 'docs_doctor/cli'
