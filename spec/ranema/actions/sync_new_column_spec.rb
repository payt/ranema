# frozen_string_literal: true

require "spec_helper"
require "ranema/actions/base"
require "ranema/actions/sync_new_column"

RSpec.describe Ranema::Actions::SyncNewColumn do
  subject(:call) { described_class.call(table_name, old_column_name, new_column_name) }

  let(:table_name) { "copy_values" }
  let(:old_column_name) { "old" }
  let(:new_column_name) { "new" }

  it "adds a migration" do
    expect { call }.to change { Ranema::Utils::MIGRATIONS_DIR.children.size }.by(1)
  end

  context "when the migration was already added" do
    before { described_class.call(table_name, old_column_name, new_column_name) }

    it "does not add another migration" do
      expect { call }.not_to change { Ranema::Utils::MIGRATIONS_DIR.children.size }
    end

    context "when running the migration" do
      before { require(Ranema::Utils::MIGRATIONS_DIR.children.last) }

      let(:instance) { described_class.new(table_name, old_column_name, new_column_name) }
      let(:migration) { instance.migration_name.camelcase.constantize }

      it "adds the new column to the table" do
        expect { migration.migrate(:up) }
          .to change { instance.send(:trigger_exists?, table_name, instance.trigger_name) }.to(true)
      end
    end
  end

  context "when the migration was run" do
    let(:instance) { described_class.new(table_name, old_column_name, new_column_name) }
    let(:migration) { instance.migration_name.camelcase.constantize }

    before do
      described_class.call(table_name, old_column_name, new_column_name)
      require(Ranema::Utils::MIGRATIONS_DIR.children.last)
      migration.migrate(:up)
    end

    it "updates the new_column when updating the old_column" do
      expect { CopyValue.take.update!(old: "new_value") }
        .to change { CopyValue.select(:new).take.new }
    end

    it "sets the new_column when inserting a new record" do
      expect { CopyValue.create!(old: "new_value") }
        .to change { CopyValue.select(:new).last.new }
    end

    context "when the migration file is deleted" do
      before { FileUtils.rm(Ranema::Utils::MIGRATIONS_DIR.children.last) }

      it "does not add another migration since the trigger still exists in the database" do
        expect { call }.not_to change { Ranema::Utils::MIGRATIONS_DIR.children.size }
      end
    end
  end
end
