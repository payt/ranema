# frozen_string_literal: true

require "spec_helper"
require "ranema/actions/base"
require "ranema/actions/add_new_column"

RSpec.describe Ranema::Actions::AddNewColumn do
  subject(:call) { described_class.call(table_name, old_column_name, new_column_name) }

  let(:table_name) { "users" }
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

      let(:migration) do
        described_class
          .new(table_name, old_column_name, new_column_name)
          .send(:migration_name).camelcase.constantize
      end

      it "adds the new column to the table" do
        expect { migration.migrate(:up) }
          .to change { ActiveRecord::Migration.column_exists?(table_name, new_column_name) }.to(true)
      end
    end
  end
end
