# Workpattern [![Build Status](https://secure.travis-ci.org/callenb/workpattern.png)](https://secure.travis-ci.org/callenb/workpattern.png)

Calculates dates and durations whilst taking into account working and non-working times.  It creates calendars similar to what you can find in project scheduling software like Microsoft project and Primavera P6.

Please use [Github Issues] to report bugs.  If you have a question about the library, please use the `workpattern` tag on [Stack Overflow].  This tag is monitored by contributors.

[Github Issues]: http://github.com/callenb/workpattern/issues
[Stack Overflow]: http://stackoverflow.com/questions/tagged/workpattern

## Getting Started

Workpattern is a library with no monkey-patching and is tested against Ruby `>= 1.9.2`.

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

## License

(The MIT License)

Copyright (c) 2012 - 2016

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
