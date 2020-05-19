# frozen_string_literal: true

require "ranema/next_step"

# @example rake db:rename[administrations,company_name,name]
desc "Creates a draft PR to rename the column of a table."
task :rename, [:table_name, :old_column_name, :new_column_name, :start_step] do |_, args|
  Ranema::NextStep.call(args.to_h)

  next if `git status | grep db/migrate`.blank?

  # HACK: prevents the annotate rake task from crashing
  Rake.application.instance_variable_set :@top_level_tasks, ["rename"] if defined?(Annotate)

  Rake::Task["db:migrate"].invoke
end
