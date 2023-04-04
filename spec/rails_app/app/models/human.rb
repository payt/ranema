# frozen_string_literal: true

class Human < ApplicationRecord
  self.table_name = "users"

  self.ignored_columns += [
    "some_column"
  ]

end
