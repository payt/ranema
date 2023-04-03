# frozen_string_literal: true

require "spec_helper"
require "ranema/actions/base"
require "ranema/actions/ignore_new_column"
require "ranema/actions/unignore_new_column"

RSpec.describe Ranema::Actions::IgnoreNewColumn do
  subject(:call) { described_class.call(table_name, old_column_name, new_column_name) }

  let(:table_name) { "users" }
  let(:old_column_name) { "e_mail" }
  let(:new_column_name) { "email" }
  let(:model_file) { Rails.root.join("app/models/user.rb") }

  # Reverts the rails_app to its original state after running an example.
  around do |example|
    FileUtils.cp_r(Ranema::Utils::APP_ROOT, "tmp")
    example.run
    FileUtils.cp_r("tmp/rails_app", Ranema::Utils::APP_ROOT.join(".."))
  end

  it "adds an ignored_columns call including the new column name" do
    expect { call }.to change { model_file.read.include?("ignored_columns") }.from(false).to(true)
  end

  context "when the column has already been ignored" do
    before { call }

    it "does not alter the correct state of the file" do
      expect { call }
      .to not_change { model_file.read.include?("ignored_columns") }.from(true)
      .and not_change { model_file.read }
    end
  end

  context "with a model with a explicit table_name" do
    let(:model_file) { Rails.root.join("app/models/human.rb") }

    it "adds the new column to the existing ignored columns" do
      expect { call }
        .to not_change { model_file.read.include?("ignored_columns") }.from(true)
        .and change { model_file.read.include?("email") }.to(true)
    end
  end
end
