# frozen_string_literal: true

require "spec_helper"
require "ranema/actions/base"
require "ranema/actions/copy_from_old_to_new_column_trigger"

RSpec.describe Ranema::Actions::CopyFromOldToNewColumnTrigger do
  subject(:call) { described_class.call(table_name, old_column_name, new_column_name) }

  let(:table_name) { "copy_values" }
  let(:old_column_name) { "old" }
  let(:new_column_name) { "new" }

  it "adds a migration" do
    expect { call }.to change { Ranema::Utils::MIGRATIONS_DIR.children.size }.by(1)
  end

  context "when the migration was already added" do
    before { call }

    it "does not add another migration" do
      expect { call }.not_to change { Ranema::Utils::MIGRATIONS_DIR.children.size }
    end

    context "when running the migration" do
      before { require(Ranema::Utils::MIGRATIONS_DIR.children.last) }

      let(:instance) { described_class.new(table_name, old_column_name, new_column_name) }
      let(:migration) { instance.migration_name.camelcase.constantize }

      it "adds the new column to the table" do
        expect { migration.migrate(:up) }
          .to change { instance.send(:trigger_exists?, instance.trigger_name) }.to(true)
      end
    end
  end

  context "when the migration was run" do
    let(:instance) { described_class.new(table_name, old_column_name, new_column_name) }
    let(:migration) { instance.migration_name.camelcase.constantize }

    before do
      call
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
  end
end
