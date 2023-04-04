# frozen_string_literal: true

require "spec_helper"
require "ranema/actions/base"
require "ranema/actions/add_new_column"

RSpec.describe Ranema::Actions::AddNewColumn do
  subject(:call) { described_class.call(table_name, old_column_name, new_column_name) }

  let(:table_name) { "users" }
  let(:old_column_name) { "old" }
  let(:new_column_name) { "new" }
  let(:model_file) { Rails.root.join("app/models/user.rb") }

  it "adds a migration" do
    expect { call }
      .to change { Ranema::Utils::MIGRATIONS_DIR.children.size }.by(1)
  end

  context "when the migration was already added" do
    before { call }

    it "does not another migration" do
      expect { call }.not_to change { Ranema::Utils::MIGRATIONS_DIR.children.size }
    end
  end
end
