# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" if File.exist?(ENV["BUNDLE_GEMFILE"])

begin
  require "simplecov"
  SimpleCov.start do
    add_filter ["/spec/", "/app/", "/config/", "/db/"]
  end
rescue LoadError
end

require "active_record"

Bundler.require(:default, :test)

ActiveRecord::Base.establish_connection("adapter" => "sqlite3", "database" => ":memory:")

class TestModel < ActiveRecord::Base
  unless table_exists?
    connection.create_table(table_name) do |t|
      t.string :name
      t.string :value
    end
  end

  include AfterCommitChanges

  attr_accessor :after_commit_changes, :before_commit_changes, :do_something

  after_commit { self.after_commit_changes = saved_changes }
  before_commit { self.before_commit_changes = saved_changes }
  after_commit -> { self.do_something = true }, if: :saved_change_to_value?, on: :update
end

RSpec.configure do |config|
  config.order = :random
end
