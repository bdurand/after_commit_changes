# frozen_string_literal: true

module AfterCommitChanges
  module Dirty
    class << self
      def prepended(base)
        base.before_commit do
          if @after_commit_saved_changes.size > 1
            @mutations_before_last_save = rollup_mutations_for_transaction
          end
          @after_commit_saved_changes = []
          @after_commit_changes_original_attributes = nil
        end

        base.before_save do
          @after_commit_changes_original_attributes ||= @attributes
        end

        base.after_save do
          @after_commit_saved_changes << saved_changes
        end
      end
    end

    def initialize(*)
      super
      @after_commit_saved_changes = []
      @after_commit_changes_original_attributes = nil
    end

    private

    def rollup_mutations_for_transaction
      attributes = @after_commit_changes_original_attributes.deep_dup

      @after_commit_saved_changes[1, @after_commit_saved_changes.length].each do |changes|
        changes.each do |attr_name, value_change|
          attribute = attributes[attr_name]
          attributes[attr_name] = ActiveModel::Attribute.from_user(attr_name, value_change.last, attribute.type, attribute)
        end
      end

      ActiveModel::AttributeMutationTracker.new(attributes)
    end
  end
end
