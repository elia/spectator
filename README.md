# Usage

In your specs.watchr file just add:

```ruby
    require 'rspec-rails-watchr'
    
    @specs_watchr ||= Rspec::Rails::Watchr.new(self)
```

Then launch `watchr` as usual (probably `bundle exec watchr`).

## Instructions

The normal behavior is similar to `autotest --fast-start --no-full-after-failed` 
but gives the user a bit more control over execution. By hitting CTRL+C (or CMD+. on OSX)
you get the following prompt:

    ^C (Interrupted with CTRL+C)
    --- What to do now? (q=quit, a=all-specs, r=reload): 

## Advanced

If you want to override some path matching:

```ruby
    @specs_watchr ||= Rspec::Rails::Watchr.new(self) do |path, specs|
      case path
      when %r{lib/calibration_with_coefficients}
        specs.grep(%r{models/(logarithmic|polynomial)_calibration})
      when %r{app/models/telemetry_parameter}
        specs.grep(%r{models/telemetry_parameter})
      end
    end
```



Copyright (c) 2011 Elia Schito, released under the MIT license
