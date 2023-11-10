# frozen_string_literal: true

require_relative "after_commit_changes/dirty"

module AfterCommitChanges
  VERSION = File.read(File.expand_path("../VERSION", __dir__)).strip

  class << self
    def included(base)
      base.prepend(Dirty)
    end
  end
end
