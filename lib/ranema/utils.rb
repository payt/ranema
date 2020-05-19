# frozen_string_literal: true

require "active_record"
require "erb"
require "rails"

module Ranema
  module Utils
    TEMPLATES_DIR = Rails.root.join("lib", "rename", "templates")
    MIGRATIONS_DIR = Rails.root.join("db", "migrate")
    JOB_DIR = Rails.root.join("app", "jobs")
    RENAMES_DIR = Rails.root.join("app", "renames").tap { |path| path.exist? || path.mkdir }

    # Returns a list of models that use the given table.
    # It removes any sti submodels to reduce the number of changes that are needed.
    #
    # @return [Array<Class>]
    def models
      @models ||= begin
        Rails.application.eager_load!
        ActiveRecord::Base.connection

        list = ActiveRecord::Base.descendants.select { |model| model.table_name == table_name }
        return list unless list.many?

        list.reject { |item| item.ancestors.any? { |ancestor| item != ancestor && list.include?(ancestor) } }
      end
    end

    def model
      @model ||= models.first
    end

    # @return [ActiveRecord::ConnectionAdapters::PostgreSQL::Column]
    def old_column
      @old_column ||= model.columns.find { |column| column.name == old_column_name }
    end

    # NOTE: when a class is in a file with a nonconventional name, its location can't be determined.
    # NOTE: when a class is in a nonconventional location AND has no instance methods, its location can't be determined.
    #
    # @param model [Class]
    # @return [String, nil]
    def location(model)
      file_name = "#{model.name.snakecase}.rb"
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

      ERB.new(file.binread, trim_mode: "-").result_with_hash(options)
    end

    # @return []
    def rails_root
      @rails_root ||= Rails.root
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
  end
end
