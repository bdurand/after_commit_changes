# frozen_string_literal: true

module AfterCommitChanges
  VERSION = File.read(File.expand_path("../VERSION", __dir__)).strip

  def self.included(base)
    base.before_commit do
      rollup_mutations_for_transaction!
    end

    base.after_save do
      @after_commit_saved_changes ||= []
      @after_commit_saved_changes << saved_changes
    end
  end

  private

  def rollup_mutations_for_transaction!
    return unless @after_commit_saved_changes && @after_commit_saved_changes.size > 1

    attributes = @_start_transaction_state[:attributes].deep_dup
    mutations = ActiveModel::AttributeMutationTracker.new(attributes)

    @after_commit_saved_changes[1, @after_commit_saved_changes.length].each do |changes|
      changes.each do |attr_name, value_change|
        attribute = attributes[attr_name]
        last_value = value_change.last
        last_value = last_value.to_h if last_value.is_a?(ActiveSupport::HashWithIndifferentAccess)
        attributes[attr_name] = ActiveModel::Attribute.from_user(attr_name, last_value, attribute.type, attribute)
        mutations.force_change(attr_name) unless mutations.changed?(attr_name)
      end
    end

    @after_commit_saved_changes = nil
    @mutations_before_last_save = mutations
  end
end
