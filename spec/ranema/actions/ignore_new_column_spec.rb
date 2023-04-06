# frozen_string_literal: true

require "spec_helper"
require "ranema/actions/base"
require "ranema/actions/ignore_new_column"

RSpec.describe Ranema::Actions::IgnoreNewColumn do
  subject(:call) { described_class.call(table_name, old_column_name, new_column_name) }

  let(:table_name) { "users" }
  let(:old_column_name) { "old" }
  let(:new_column_name) { "new" }
  let(:model_file) { Rails.root.join("app/models/user.rb") }

  it "adds an ignored_columns call including the new column name" do
    expect { call }
      .to change { model_file.read.include?("ignored_columns") }.to(true)
      .and change { model_file.read.include?(new_column_name) }.to(true)
  end

  context "with a model with an explicit table_name" do
    let(:model_file) { Rails.root.join("app/models/human.rb") }

    it "adds the new column to the existing ignored columns" do
      expect { call }
        .to not_change { model_file.read.include?("ignored_columns") }.from(true)
        .and change { model_file.read.include?(new_column_name) }.to(true)
    end
  end

  context "when the column has already been ignored" do
    before do
      described_class.call(table_name, old_column_name, new_column_name)
      Rails.application.reloader.reload!
    end

    it "does not alter the correct state of the file" do
      expect { call }
        .to not_change { model_file.read.include?("ignored_columns") }.from(true)
        .and not_change { model_file.read.include?(new_column_name) }.from(true)
        .and not_change { model_file.read }
    end
  end
end
