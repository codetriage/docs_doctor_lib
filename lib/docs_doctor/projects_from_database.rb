require "sequel"

module DocsDoctor

  # Connects to a given database and pulls info for each project
  #
  # Example:
  #
  #   projects_from_database = DocsDoctor::ProjectsFromDatabase.new(language: "Ruby")
  #   projects_from_database.call do |hash|
  #     puts hash[:full_name] # => 'rails/rails'
  #   end
  #
  class ProjectsFromDatabase

    def initialize(language: )
      @language = language
    end

    def call
      database.fetch("select full_name from repos where language=?", @language).each do |hash|
        yield hash
      end
    ensure
      disconnect
    end

    private
      def database
        @db ||= Sequel.connect(ENV.fetch("DATABASE_URL"), max_connections: 1) # Don't hog connections
      end

      def disconnect
        @db.disconnect && @db = nil
      end
  end
end
