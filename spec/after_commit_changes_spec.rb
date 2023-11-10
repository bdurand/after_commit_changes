# frozen_string_literal: true

require_relative "spec_helper"

describe AfterCommitChanges do
  context "with no updates in a transaction" do
    it "does not have any saved changes" do
      record = TestModel.create!(name: "foo", value: "bar")
      record.save!
      expect(record.after_commit_changes).to be_empty
      expect(record.saved_changes).to be_empty
    end
  end

  context "with one update in a transaction" do
    it "tracks all changes on a new record" do
      record = TestModel.create!(name: "foo", value: "bar")
      expect(record.after_commit_changes).to eq("id" => [nil, record.id], "name" => [nil, record.name], "value" => [nil, record.value])
      expect(record.before_commit_changes).to eq("id" => [nil, record.id], "name" => [nil, record.name], "value" => [nil, record.value])
      expect(record.saved_changes).to eq("id" => [nil, record.id], "name" => [nil, record.name], "value" => [nil, record.value])
    end

    it "has the standard changes if there was only one update in the transaction" do
      record = TestModel.create!(name: "foo", value: "bar")
      record.update!(name: "baz")
      expect(record.after_commit_changes).to eq("name" => %w[foo baz])
      expect(record.saved_changes).to eq("name" => %w[foo baz])
    end

    it "clears changes between transactions" do
      record = TestModel.create!(name: "foo", value: "bar")
      record.update!(name: "baz")
      record.update!(value: "biz")
      expect(record.after_commit_changes).to eq("value" => %w[bar biz])
      expect(record.saved_changes).to eq("value" => %w[bar biz])
    end
  end

  context "with multiple updates in a transaction" do
    it "tracks all changes on a new record" do
      record = nil
      TestModel.transaction do
        record = TestModel.create!(name: "foo", value: "bar")
        record.update!(name: "baz")
      end
      expect(record.after_commit_changes).to eq("id" => [nil, record.id], "name" => [nil, record.name], "value" => [nil, record.value])
      expect(record.before_commit_changes).to eq("id" => [nil, record.id], "name" => [nil, record.name], "value" => [nil, record.value])
      expect(record.saved_changes).to eq("id" => [nil, record.id], "name" => [nil, record.name], "value" => [nil, record.value])
    end

    it "aggregates all changes in a transaction" do
      record = TestModel.create!(name: "foo", value: "bar")
      record.transaction do
        record.update!(name: "baz")
        record.update!(value: "biz")
        record.update!(name: "fub")
      end
      expect(record.after_commit_changes).to eq("name" => %w[foo fub], "value" => %w[bar biz])
      expect(record.saved_changes).to eq("name" => %w[foo fub], "value" => %w[bar biz])
    end

    it "aggregates all changes in a transaction even if the last one is a no op" do
      record = TestModel.create!(name: "foo", value: "bar")
      record.transaction do
        record.update!(name: "baz")
        record.save!
      end
      expect(record.after_commit_changes).to eq("name" => %w[foo baz])
      expect(record.saved_changes).to eq("name" => %w[foo baz])
    end

    it "honors all dirty values in filters declared on commit callbacks" do
      record = TestModel.create!(name: "foo", value: "bar")
      record.conditional_callbacks = nil

      record.transaction do
        record.update!(name: "biz")
      end
      expect(record.conditional_callbacks).to be_nil

      record.transaction do
        record.update!(value: "biz")
        record.update!(name: "baz")
      end

      expect(record.conditional_callbacks).to match_array([:before_commit, :after_commit])
    end

    it "clears changes between transactions" do
      record = TestModel.create!(name: "foo", value: "bar")

      record.transaction do
        record.update!(name: "baz")
        record.update!(value: "biz")
        record.update!(name: "fub")
      end
      expect(record.saved_changes).to eq("name" => %w[foo fub], "value" => %w[bar biz])

      record.transaction do
        record.update!(name: "foo")
      end

      expect(record.saved_changes).to eq("name" => %w[fub foo])
    end

    it "responds to all dirty methods for saved changes" do
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

    it "does not mess with the model attributes" do
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

    it "handles an attribute being set back to the original value as a change" do
      record = TestModel.create!(name: "foo", value: "bar")
      record.reload

      record.transaction do
        record.update!(name: "baz")
        record.update!(value: "biz")
        record.update!(name: "foo")
      end

      expect(record.saved_change_to_name?).to eq(true)
      expect(record.saved_changes).to eq("name" => %w[foo foo], "value" => %w[bar biz])
    end

    it "handles calling will_change to force an attribute to be marked as changed" do
      record = TestModel.create!(name: "foo", value: "bar")
      record.reload

      record.transaction do
        record.update!(value: "biz")
        record.name_will_change!
        record.save!
      end

      expect(record.saved_change_to_name?).to eq(true)
      expect(record.saved_changes).to eq("name" => %w[foo foo], "value" => %w[bar biz])
    end
  end
end
