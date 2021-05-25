# Ranema

Renames database columns safely in large production environments.

## Usage

Ranema generates a series of Pull Requests that rename a database column in steps to prevent any downtime on the production environment and it mitigates the risks involved in any rename process. It basically acts a developer who's sole job it is to rename database columns, much like what Dependabot is to keeping gems up-to-date.

#### Step 1

The first step is to tell Ranema what to do. Tell it which column to rename like so:
```console
rake ranema[my_table_name,old_column_name,new_column_name]
```

This will do a few things:
1. It will create a YAML file in which Ranema will store which renames it is working on and the last step in took in each of those processes.
2. it will start the rename process by adding the `new_column_name` to the `self.ignored_columns` lists of all models using that table containing the column to be renamed. This ensures that the next step, adding the new column, does not break any running database transactions.
3. It looks for any raw SQL that contains the old_column_name without the table prefix. If any are found then the table name is prefixed to the old_column_name. This prefixing prevents the breaking of queries where the `table` is joined with another table that also contains a column with the `new_column_name`.

#### Step 2

The second step is to create the column with the new name. It will add triggers to ensure that the new column is kept insync with old column and a background process is started to backfill existing records.

#### Step 3

All database checks, constraints, and indices that are present on the old column are created on the new column.

#### Step 4

The new column is ignored and be used from now on. Deprecation warning are added to warn other developers when the old column is used. The deprecation warnings are added to Rails and to the database.

Ranema helps out with replacing all occurrences of the old_column_name in the codebase with the new_column_name. This process is obviously limited in what it can find. Ranema makes a number of assumptions about naming conventions. If the other devs in your team keep to the same naming conventions then Ranema should be able to find most occurrences by itself, leaving it to you to check at the end of your CI run if any deprecation warnings have been logged.

#### Step 5

Adds the `old_column_name` to the `self.ignored_columns` lists of all models using that table. This ensures that the next step, removing the old column, does not break any running database transactions.

#### Step 6

Removes the old column and any code added during the rename process.

## Customization

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ranema', group: :development
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ranema

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/payt/ranema.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
