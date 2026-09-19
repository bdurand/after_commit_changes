# frozen_string_literal: true

require "spec_helper"

# This model intentionally does NOT include AfterCommitChanges so that the
# specs below exercise the unpatched ActiveRecord behavior.
class UpstreamTestModel < ActiveRecord::Base
  unless table_exists?
    connection.create_table(table_name) do |t|
      t.string :name
      t.string :value
    end
  end

  attr_accessor :after_commit_changes, :before_commit_changes, :conditional_callbacks

  after_commit { self.after_commit_changes = saved_changes }
  before_commit { self.before_commit_changes = saved_changes }

  before_commit -> { conditional_callback(:before_commit) }, if: :saved_change_to_value?
  after_commit -> { conditional_callback(:after_commit) }, if: :saved_change_to_value?

  private

  def conditional_callback(callback)
    self.conditional_callbacks ||= []
    conditional_callbacks << callback
  end
end

# These specs assert that the upstream ActiveRecord bug this gem works around
# (https://github.com/rails/rails/pull/50011) still exists in the version of
# ActiveRecord under test.
#
# If these specs start failing, it means ActiveRecord now aggregates saved
# changes across multiple saves in a transaction and this gem may no longer be
# needed for that version of ActiveRecord.
RSpec.describe "ActiveRecord without AfterCommitChanges" do
  let(:upstream_fixed_message) do
    "ActiveRecord #{ActiveRecord::VERSION::STRING} appears to have fixed " \
      "https://github.com/rails/rails/pull/50011; this gem may no longer be needed for this version."
  end

  it "only exposes the changes from the last save in commit callbacks" do
    record = UpstreamTestModel.create!(name: "foo", value: "bar")

    record.transaction do
      record.update!(name: "baz")
      record.update!(value: "biz")
    end

    expect(record.before_commit_changes).to eq("value" => %w[bar biz]), upstream_fixed_message
    expect(record.after_commit_changes).to eq("value" => %w[bar biz]), upstream_fixed_message
    expect(record.saved_changes).to eq("value" => %w[bar biz]), upstream_fixed_message
  end

  it "does not fire conditional commit callbacks for changes from an earlier save in the transaction" do
    record = UpstreamTestModel.create!(name: "foo", value: "bar")
    record.conditional_callbacks = nil

    record.transaction do
      record.update!(value: "biz")
      record.update!(name: "baz")
    end

    expect(record.conditional_callbacks).to be_nil, upstream_fixed_message
  end
end
