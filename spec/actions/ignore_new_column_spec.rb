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

  after do
    Ranema::Actions::UnignoreNewColumn.call(table_name, old_column_name, new_column_name)
  end

  it 'adds an ignored_columns call including the new column name' do
    expect { call }.to change { model_file.read.include?("ignored_columns") }.from(false).to(true)
  end
end
