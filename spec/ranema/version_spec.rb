# frozen_string_literal: true

RSpec.describe Ranema do
  it "has a version number" do
    expect(Ranema::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
