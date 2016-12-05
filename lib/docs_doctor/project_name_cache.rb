module DocsDoctor
  # Caches all projects in a file so that we don't have to keep a database connection open
  class ProjectNameCache
    def initalize(projects_from_db: , file: )
      @projects_from_db = projects_from_db
      @file             = file
    end

    def write
      File.open(@file, 'w') do |f|
        @projects_from_db.call do |hash|
          f.puts hash[:full_name]
        end
      end
    end

    def read_each
      File.read(@file).each_line do |line|
        yield line
      end
    end
  end
end
