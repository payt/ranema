# frozen_string_literal: true

module Ranema
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/ranema.rake"
    end
  end
end
