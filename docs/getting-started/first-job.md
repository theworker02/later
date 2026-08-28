# Your first durable job

```ruby
require "later"

Later.configure(path: "tmp/later.sqlite3")
Later.call(Reports, :generate_monthly, at: Time.now + 60)
```

Run `later run` in the application environment. Use a named constant and JSON-compatible arguments when a job must survive a process restart.
