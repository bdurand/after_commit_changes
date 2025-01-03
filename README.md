# AfterCommitChanges

[![Continuous Integration](https://github.com/bdurand/after_commit_changes/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/bdurand/after_commit_changes/actions/workflows/continuous_integration.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)
[![Gem Version](https://badge.fury.io/rb/after_commit_changes.svg)](https://badge.fury.io/rb/after_commit_changes)

This gem addresses an [issue in ActiveRecord](https://github.com/rails/rails/pull/50011) with the `saved_changes` value when a record is updated multiple times in a single database transaction.

After a record is saved, you can check the set of changes with the `saved_changes` method using the [ActiveModel::Dirty API](https://api.rubyonrails.org/classes/ActiveModel/Dirty.html). However, when a record is saved multiple times, the list of saved changes is reset with each save operation. This can be an issue inside of an `after_commit` or `before_commit` callback since those callbacks are only called once for the transaction and will only get the last set of changes.

This can be a problem if you have a callback that checks for changes to specific fields. Consider this model where we want to run an asychronous job when a user changes their email address:

```ruby
class User < ApplicationRecord
  after_commit :notify_email_changes, if: :email_changed?

  def notify_email_changes
    NotifyEmailChangesJob.perform_later(id)
  end
end
```

This breaks down if a record is saved twice in a single transaction.

```ruby
user.transaction do
  user.update!(email: params[:email])
  if user.last_visited_at < 1.day.ago
    user.update!(last_visited_at: Time.now)
  end
end
```

In the case where we update the `last_visited_at` field, the `email_changed?` method will return false since the email address was not changed in the last save operation and `notify_email_changes` method will not be called.

This gem addresses this issue by merging all saved changes together before calling the `after_commit` or `before_commit` callbacks so that `saved_changes` will return the complete list of changes for the transaction.

## Usage

To use the gem, you simply need to mix it into your models. You can include it in all models by including it in your `ApplicationRecord` class:

```ruby
class ApplicationRecord < ActiveRecord::Base
  include AfterCommitChanges
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem "after_commit_changes"
```

Then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install gem "after_commit_changes"
```

## Contributing

Open a pull request on GitHub.

Please use the [standardrb](https://github.com/testdouble/standard) syntax and lint your code with `standardrb --fix` before submitting.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
