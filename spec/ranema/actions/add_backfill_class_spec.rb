# frozen_string_literal: true

require "spec_helper"
require "ranema/actions/base"
require "ranema/actions/add_backfill_class"

RSpec.describe Ranema::Actions::AddBackfillClass do
  subject(:call) { described_class.call(table_name, old_column_name, new_column_name) }

  let(:table_name) { "copy_values" }
  let(:old_column_name) { "old" }
  let(:new_column_name) { "new" }

  it "adds the class to the repo" do
    expect { call }.to change { Ranema::Utils::RENAMES_DIR.children.size }.by(1)
  end

  context "when the backfill was already added" do
    before { described_class.call(table_name, old_column_name, new_column_name) }

    it "does not add another backfill" do
      expect { call }.not_to change { Ranema::Utils::RENAMES_DIR.children.size }
    end

    context "when running the backfill class" do
      before { require(Ranema::Utils::RENAMES_DIR.children.last) }

      let(:instance) { described_class.new(table_name, old_column_name, new_column_name) }
      let(:backfill) { instance.class_name.constantize }

      it "backfills the new column" do
        expect { backfill.call }.to change { instance.model.where(new: nil).count }.by(-1)
      end
    end
  end
end
