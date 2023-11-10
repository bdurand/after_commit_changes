# frozen_string_literal: true

require_relative "spec_helper"

describe AfterCommitChanges do
  context "with no updates in a transaction" do
    it "should not have any saved changes" do
      record = TestModel.create!(name: "foo", value: "bar")
      record.save!
      expect(record.after_commit_changes).to be_empty
      expect(record.saved_changes).to be_empty
    end
  end

  context "with one update in a transaction" do
    it "should have all changes on a new record" do
      record = TestModel.create!(name: "foo", value: "bar")
      expect(record.after_commit_changes).to eq("id" => [nil, record.id], "name" => [nil, record.name], "value" => [nil, record.value])
      expect(record.before_commit_changes).to eq("id" => [nil, record.id], "name" => [nil, record.name], "value" => [nil, record.value])
      expect(record.saved_changes).to eq("id" => [nil, record.id], "name" => [nil, record.name], "value" => [nil, record.value])
    end

    it "should have the standard changes if there was only one update in the transaction" do
      record = TestModel.create!(name: "foo", value: "bar")
      record.update!(name: "baz")
      expect(record.after_commit_changes).to eq("name" => %w[foo baz])
      expect(record.saved_changes).to eq("name" => %w[foo baz])
    end

    it "should clear changes between transactions" do
      record = TestModel.create!(name: "foo", value: "bar")
      record.update!(name: "baz")
      record.update!(value: "biz")
      expect(record.after_commit_changes).to eq("value" => %w[bar biz])
      expect(record.saved_changes).to eq("value" => %w[bar biz])
    end
  end

  context "with multiple updates in a transaction" do
    it "should have all changes on a new record" do
      record = nil
      TestModel.transaction do
        record = TestModel.create!(name: "foo", value: "bar")
        record.update!(name: "baz")
      end
      expect(record.after_commit_changes).to eq("id" => [nil, record.id], "name" => [nil, record.name], "value" => [nil, record.value])
      expect(record.before_commit_changes).to eq("id" => [nil, record.id], "name" => [nil, record.name], "value" => [nil, record.value])
      expect(record.saved_changes).to eq("id" => [nil, record.id], "name" => [nil, record.name], "value" => [nil, record.value])
    end

    it "should aggregate all changes in a transaction" do
      record = TestModel.create!(name: "foo", value: "bar")
      record.transaction do
        record.update!(name: "baz")
        record.update!(value: "biz")
        record.update!(name: "fub")
      end
      expect(record.after_commit_changes).to eq("name" => %w[foo fub], "value" => %w[bar biz])
      expect(record.saved_changes).to eq("name" => %w[foo fub], "value" => %w[bar biz])
    end

    it "should aggregate all changes in a transaction even if the last one is a no op" do
      record = TestModel.create!(name: "foo", value: "bar")
      record.transaction do
        record.update!(name: "baz")
        record.save!
      end
      expect(record.after_commit_changes).to eq("name" => %w[foo baz])
      expect(record.saved_changes).to eq("name" => %w[foo baz])
    end

    it "should honor all dirty values in callback filters" do
      record = TestModel.create!(name: "foo", value: "bar")
      record.do_something = false

      record.transaction do
        record.update!(value: "biz")
        record.update!(name: "baz")
      end

      expect(record.do_something).to eq(true)
    end

    it "should clear changes between transactions" do
      record = TestModel.create!(name: "foo", value: "bar")
      record.transaction do
        record.update!(name: "baz")
        record.update!(value: "biz")
        record.update!(name: "fub")
      end
      record.transaction do
        record.update!(name: "foo")
      end
      expect(record.after_commit_changes).to eq("name" => %w[fub foo])
      expect(record.saved_changes).to eq("name" => %w[fub foo])
    end

    it "should respond to all dirty methods for saved changes" do
      record = TestModel.create!(name: "foo", value: "bar")
      record.reload

      record.transaction do
        record.update!(name: "baz")
        record.update!(value: "biz")
        record.update!(name: "bap")
      end

      expect(record.saved_change_to_name?).to eq(true)
      expect(record.name_previous_change).to eq(%w[foo bap])

      expect(record.saved_change_to_value?).to eq(true)
      expect(record.value_previous_change).to eq(%w[bar biz])
    end

    it "should not mess up the model attributes" do
      record = TestModel.create!(name: "foo", value: "bar")
      record.reload

      record.transaction do
        record.update!(name: "baz")
        record.update!(value: "biz")
        record.update!(name: "bap")
      end

      expect(record.name).to eq("bap")
      expect(record.value).to eq("biz")
    end

    it "should handle an attribute being set back to the original value" do
      record = TestModel.create!(name: "foo", value: "bar")
      record.reload

      record.transaction do
        record.update!(name: "baz")
        record.update!(value: "biz")
        record.update!(name: "foo")
      end

      expect(record.saved_change_to_name?).to eq(false)
      expect(record.saved_changes).to eq("value" => %w[bar biz])
    end
  end
end
