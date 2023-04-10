# frozen_string_literal: true

require "spec_helper"
require "ranema/actions/base"
require "ranema/actions/add_backfill_migration"

RSpec.describe Ranema::Actions::AddBackfillMigration do
  subject(:call) { described_class.call(table_name, old_column_name, new_column_name) }

  let(:table_name) { "copy_values" }
  let(:old_column_name) { "old" }
  let(:new_column_name) { "new" }

  it "adds the migration" do
    expect { call }.to change { Ranema::Utils::MIGRATIONS_DIR.children.size }.by(1)
  end

  context "when the backfill was already added" do
    before { described_class.call(table_name, old_column_name, new_column_name) }

    it "does not add another backfill" do
      expect { call }.not_to change { Ranema::Utils::MIGRATIONS_DIR.children.size }
    end

    context "when running the migration" do
      before do
        add_backfill_class.call
        require(Ranema::Utils::MIGRATIONS_DIR.children.last.to_s)
      end

      let(:add_backfill_class) { Ranema::Actions::AddBackfillClass.new(table_name, old_column_name, new_column_name) }
      let(:backfill_class) { add_backfill_class.class_name.constantize }
      let(:migration) do
        described_class
          .new(table_name, old_column_name, new_column_name)
          .send(:migration_name).camelcase.constantize
      end

      it "backfills the new column" do
        expect { migration.migrate(:up) }.to change { add_backfill_class.model.where(new: nil).count }.by(-1)
      end
    end
  end
end
