# Usage

Launch `spectator` as usual (probably `bundle exec spectator`).

## Instructions

The normal behavior is similar to `autotest --fast-start --no-full-after-failed` 
but gives the user a bit more control over execution. By hitting CTRL+C (or CMD+. on OSX)
you get the following prompt:

    ^C (Interrupted with CTRL+C)
    --- What to do now? (q=quit, a=all-specs, r=reload): 

## Advanced (upcoming!)

If you want to override some path matching:

```ruby
    spectate do
      case path
      when %r{lib/calibration_with_coefficients}
        specs.grep(%r{models/(logarithmic|polynomial)_calibration})
      when %r{app/models/telemetry_parameter}
        specs.grep(%r{models/telemetry_parameter})
      end
    end
```



Copyright (c) 2011-2012 Elia Schito, released under the [MIT license](https://github.com/elia/spectator/blob/master/MIT-LICENSE)
