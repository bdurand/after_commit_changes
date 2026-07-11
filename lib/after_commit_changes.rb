# frozen_string_literal: true

module AfterCommitChanges
  VERSION = File.read(File.expand_path("../VERSION", __dir__)).strip

  def self.included(base)
    base.before_commit do
      rollup_mutations_for_transaction!
    end

    base.after_save do
      @after_commit_saved_changes ||= []
      @after_commit_saved_changes << [self.class.connection.open_transactions, saved_changes]
    end

    base.after_rollback do
      if @after_commit_saved_changes
        depth = self.class.connection.open_transactions
        @after_commit_saved_changes.reject! { |entry_depth, _changes| entry_depth > depth }
        @after_commit_saved_changes = nil if @after_commit_saved_changes.empty?
      end
    end
  end

  private

  def rollup_mutations_for_transaction!
    saved_changes_list = @after_commit_saved_changes
    @after_commit_saved_changes = nil
    return unless saved_changes_list && saved_changes_list.size > 1

    attributes = @_start_transaction_state[:attributes].deep_dup
    mutations = ActiveModel::AttributeMutationTracker.new(attributes)

    saved_changes_list.each do |_depth, changes|
      changes.each do |attr_name, value_change|
        attribute = attributes[attr_name]
        last_value = value_change.last
        last_value = last_value.to_h if last_value.is_a?(ActiveSupport::HashWithIndifferentAccess)
        attributes[attr_name] = ActiveModel::Attribute.from_user(attr_name, last_value, attribute.type, attribute)
        mutations.force_change(attr_name) unless mutations.changed?(attr_name)
      end
    end

    @mutations_before_last_save = mutations
  end
end
