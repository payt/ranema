# frozen_string_literal: true

require "active_record"
require "erb"
require "rails"

module Ranema
  # Collection of convenience methods
  module Utils
    APP_ROOT = Rails.root || Pathname("spec/rails_app")
    TEMPLATES_DIR = APP_ROOT.join("lib", "templates", "ranema")
    MIGRATIONS_DIR = APP_ROOT.join("db", "migrate")
    JOBS_DIR = APP_ROOT.join("app", "jobs")
    RENAMES_DIR = APP_ROOT.join("db", "ranema").tap { |path| path.exist? || path.mkdir }
    SEARCH_DIRS = ["app", "lib", "spec"].freeze
    REPLACE_DIRS = ["app", "lib", "spec"].freeze

    def rename_key
      key = "#{table_name}_#{old_column_name}_#{new_column_name}"
      return key if key.size <= 32

      key = "#{table_name}_#{old_column_name}"
      return key if key.size <= 32

      Digest::MD5.hexdigest(key)
    end

    # Returns a list of models that use the given table.
    # It removes any sti submodels to reduce the number of changes that are needed.
    #
    # @return [Array<Class>]
    def models
      @models ||= begin
        load_app

        list = ActiveRecord::Base.descendants.select { |model| model.table_name == table_name }

        if list.many?
          list.reject { |item| item.ancestors.any? { |ancestor| item != ancestor && list.include?(ancestor) } }
        else
          list
        end
      end
    end

    def model
      @model ||= models.first
    end

    def model_name
      @model_name ||= model.name.underscore
    end

    # @return [ActiveRecord::ConnectionAdapters::PostgreSQL::Column]
    def old_column
      @old_column ||=
        ActiveRecord::Base
        .connection
        .send(:column_definitions, table_name)
        .find { |field| field[0] == old_column_name }
        .then { |field| ActiveRecord::Base.connection.send(:new_column_from_field, table_name, field, nil) }
    end

    # NOTE: when a class is in a file with a unconventional name, its location can't be determined.
    # NOTE: when a class is in a unconventional location AND has no instance methods, its location can't be determined.
    #
    # @param model [Class]
    # @return [String, nil]
    def location(model)
      file_name = "#{model.name.underscore}.rb"
      conventional = rails_root.join("app", "models", file_name)
      return conventional.to_s if conventional.exist?

      model
        .instance_methods(false)
        .map { |method| model.instance_method(method).source_location.first }
        .find { |location| location.starts_with?(rails_root.to_s) && location.ends_with?("/#{file_name}") }
    end

    def render_template(name, options)
      file = TEMPLATES_DIR.join("#{name}.rb.tt")
      file = file.exist? ? file : Pathname.new("#{Ranema::ROOT_DIR}/ranema/templates/#{name}.rb.tt")
      options = {
        i: indentation,
        q: quote,
        table_name: table_name,
        old_column_name: old_column_name,
        new_column_name: new_column_name
      }.merge(options)

      ERB.new(file.binread, trim_mode: "-").result_with_hash(options)
    end

    # @return [Array<String>] array of all file names to search through.
    def search_in_files
      SEARCH_DIRS
        .flat_map { |dir| Dir[rails_root.join(dir, "**", "*")] }
        .select { |entry| File.file?(entry) }
    end

    # @return [Array<String>] array of file names that are linked to the table in which the rename takes place.
    def replace_in_files
      REPLACE_DIRS
        .flat_map { |dir| Dir[rails_root.join(dir, "**", "*#{model_name}*")] }
        .concat(REPLACE_DIRS.flat_map { |dir| Dir[rails_root.join(dir, "**", model_name, "**", "*")] })
        .select { |entry| File.file?(entry) }
        .grep_v(file_names_to_skip)
    end

    # @return [Regexp] regexp with files where just the name of the model in the filename is a false-positive.
    def file_names_to_skip
      @file_names_to_skip ||= Regexp.union(
        ActiveRecord::Base
        .descendants
        .map { |klass| klass.name.underscore }
        .select { |name| name.include?(model_name) && name != model_name }
      )
    end

    # @return []
    def rails_root
      @rails_root ||= APP_ROOT
    end

    # TODO: determine from codebase, or make it a setting
    # NOTE: assumes the same indentation is used throughout the codebase.
    #
    # @return [String]
    def indentation
      @indentation ||= "  "
    end

    # TODO: determine from codebase, or make it a setting
    # NOTE: assumes the same quotation is used throughout the codebase.
    #
    # @return [String]
    def quote
      @quote ||= "\""
    end

    private

    def load_app
      Rails.application.eager_load!
      ActiveRecord::Base.connection
    end
  end
end
