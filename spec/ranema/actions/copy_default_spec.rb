# frozen_string_literal: true

require "spec_helper"
require "ranema/actions/base"
require "ranema/actions/copy_default"

RSpec.describe Ranema::Actions::CopyDefault do
  subject(:call) { described_class.call(table_name, old_column_name, new_column_name) }

  let(:table_name) { "defaults" }
  let(:old_column_name) { "old_string" }
  let(:new_column_name) { "new_string" }

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
      let(:migration) { instance.send(:migration_name).camelcase.constantize }

      it "sets the default on the new column" do
        expect { migration.migrate(:up) }
          .to change { instance.send(:new_column_default) }.from(nil).to("'unknown'::character varying")
      end
    end
  end

  context "with a boolean column" do
    let(:old_column_name) { "old_boolean" }
    let(:new_column_name) { "new_boolean" }

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
        let(:migration) { instance.send(:migration_name).camelcase.constantize }

        it "sets the default on the new column" do
          expect { migration.migrate(:up) }
            .to change { instance.send(:new_column_default) }.from(nil).to("false")
        end
      end
    end
  end

  context "when the default is a function" do
    let(:old_column_name) { "old_timestamp" }
    let(:new_column_name) { "new_timestamp" }

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
        let(:migration) { instance.send(:migration_name).camelcase.constantize }

        it "sets the default on the new column" do
          expect { migration.migrate(:up) }
            .to change { instance.send(:new_column_default) }.from(nil).to("transaction_timestamp()")
        end
      end
    end
  end
end
