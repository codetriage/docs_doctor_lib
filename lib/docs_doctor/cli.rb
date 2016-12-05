module DocsDoctor
  # Top level class used to invoke commands, see `ext/docs_doctor` for usage
  class CLI
    attr_reader :argv, :language, :script_path

    def initialize(argv: argv = ARGV, language: , script_path: "bin/document")
      @argv        = argv
      @language    = language
      @script_path = script_path
      @cache_file  = Tempfile.open('project_name_cache')
      projects_from_db    = ProjectsFromDatabase.new(language: language)
      @project_name_cache = ProjectNameCache.new(projects_from_db: projects_from_db, cache_file: @cache_file)
    end

    # Write to project names to file cache, close DB connection
    # Read each project name from cache
    # `git clone` each project name
    # call the specified script and pass in the directory of the `git clone` project along with
    # a file the project can write docs to.
    def enqueue
      each_name_for_language do |full_name|
        fetcher = GithubFetcher.new(full_name)
        fetcher.clone_exec do |dir|
          Tempfile.open('output.json-docs') do |output_file|
          run_script("#{script_path} --repo_path='#{directory}'' --output_file='#{output_file}'")
          export_docs_from_file_to_db(output_file)
        end
      end
      errors = each_project_directory_and_output_file do |directory, output_file|

      end
      raise errors.first unless errors.empty?
    end

  private

    def export_docs_from_file_to_db(output_file)
      write_docs = UpdateProjectDocs.new.connect
      File.read(output_file).each_line do |line|
        json = JSON.parse(line)
        json[:commit_sha]       = fetcher.commit_sha
        json[:github_full_name] = full_name
        write_docs.create_from(json)
      end
    ensure
      write_docs.disconnect
    end
    def cleanup
      FileUtils.remove_entry(@cache_file)
    end

    def each_project_directory_and_output_file
      errors = []
      each_name_for_language do |name|
        begin
          fetch(name) do |directory, file|
            yield directory, file
          end
        rescue => e
          errors << e
          log_exception(e)
        end
      end
      errors
    end

    def log_exception(e)
      puts e.message
    end

    def run_script(cmd)
      out = ""
      err = ""
      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        err = stderr.read
        out = stdout.read
      end
      raise ScriptExecutionError.new("Exception running #{cmd.inspect}", err: err, out: out) unless $?.success?
      out
    end

    def output_file
      Tempfile.open('output.json-docs') do |f|
        yield f
      end
    end

    def fetch(name) # "rails/rails"
      fetcher = GithubFetcher.new(name)
      directory = fetcher.clone
      output_file do
        yield directory, file
      end
    ensure
      fetcher.cleanup
    end

    def each_name_for_language
      @project_name_cache.write
      @project_name_cache.read_each do |name|
        yield name
      end
    end
  end
end

# `bin/docs_doctor enqueue:all Ruby`
#
# cli = DocsDoctor::CLI.new(argv: ARGV, language: "Ruby")
# cli.enqueue
#
#