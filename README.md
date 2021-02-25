# Workpattern [![Build Status](https://secure.travis-ci.org/callenb/workpattern.png)](https://secure.travis-ci.org/callenb/workpattern.png)

Calculates dates and durations whilst taking into account working and non-working times.  It creates calendars similar to what you can find in project scheduling software like Microsoft project and Primavera P6.

Please use [Github Issues] to report bugs.  If you have a question about the library, please use the `workpattern` tag on [Stack Overflow].  This tag is monitored by contributors.

[Github Issues]: http://github.com/callenb/workpattern/issues
[Stack Overflow]: http://stackoverflow.com/questions/tagged/workpattern

## Getting Started

Workpattern is a library with no monkey-patching and was tested using [Travis](https://travis-ci.org) against the following Ruby versions `1.9.3`, `2.1`, `2.2`, `2.3`, `2.4`, `2.5`, `2.6`, `ruby-head (3.1.0dev)`, `jruby-19mode (9.2.9.0 (2.5.7)` and `jruby-head (9.3.0.0-SNAPSHOT (2.6.5)`.

You can install it using:
```sh
gem install workpattern
```

Or you can add it to your Gemfile with:

```sh
gem "workpattern"
```

Then run the bundle command to install it.

## Use

## Configure and Calculate

First create a `Workpattern` to hold all the working and resting times.

``` ruby
mywp=Workpattern.new 'My Workpattern',2011,10 
```
That line created a `Workpattern` called `My Workpattern` starting on 1-Jan-2011 and continuing for `10` years until `2020`.

`mywp` is created with a 24 hour a day working time.  Next step is to tell it to ignore weekends by making every Saturday and Sunday non-working.

``` ruby
mywp.resting :days => :weekend 
```

The `Workpattern.clock` method can be used to specify the non-working times for each weekday.  Any class that responds to `#hour` and `#min` methods such as `Time` or `DateTime` can be used instead of `Workpattern.clock`.

``` ruby
mywp.resting :days =>:weekday, :from_time=>Workpattern.clock(0,0),:to_time=>Workpattern.clock(8,59) 
mywp.resting :days =>:weekday, :from_time=>Workpattern.clock(12,0),:to_time=>Workpattern.clock(12,59) 
mywp.resting :days =>:weekday, :from_time=>Workpattern.clock(18,0),:to_time=>Workpattern.clock(23,59) 
```
As well as `:weekend` and `:weekday` it is possible to use `:mon`, `:tue`, `:wed`, `:thu`, `:fri`, `:sat`, `:sun` or `all`.

With `mywp` setup, the `#calc` method is used to add 32 hours which must be supplied as the number of whole minutes (1920) to a date.

``` ruby
my_date=Time.gm 2011,9,1,9,0 
result_date = mywp.calc my_date,1920  # => 6/9/11@18:00
```

The result takes into account the non-working or resting times.

Subtracting a date is just as easy by using a negative number of minutes in `#calc`.

Finding the duration between two dates is also easy using the `#diff` method.

``` ruby
diff_result = mywp.diff my_date, result_date  # => 1920
```

Vacations can be added to the `Workpattern` using the `#resting` method:

``` ruby
mywp.resting :days => :all, :start => DateTime.civil(2011,5,1), :finish => DateTime.civil(2011,5,7)
```
Find out if a specific date and time is working or not.

``` ruby
mydate = DateTime.civil 2011,5,2,9,10
mywp.resting? mydate  # => true
mywp.working? mydate  # => false
```

### Manage

``` ruby
# Fetch a specific Workpattern
Workpattern.get "My Workpattern"

# Delete a specific Workpattern
Workpattern.delete "My Workpattern"

# Delete all Workpatterns
Workpattern.clear
```