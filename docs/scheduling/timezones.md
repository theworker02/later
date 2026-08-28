# Time zones

`Later.every` stores a recurrence intermediate representation rather than only the original text:

```ruby
Later.every("weekday at 09:00", timezone: "America/New_York") { Digest.send }
```

Install and load `tzinfo` in the application when IANA timezone conversion is required. Without it, the runtime uses the host local timezone and does not claim full DST ambiguity handling.
