## What?

Simple addition and subtraction of minutes on dates taking account of real-life working and resting periods.

This gem has the potential to serve as the engine for scheduling algorithms that are the core of products such as Microsoft Project and Oracle Primavera P6 as well as other applications that need to know when they can perform work and when they can’t.

## Install

  `sudo gem install workpattern`

## Getting Started

The first step is to create a **Workpattern** to hold all the working and resting times.  I'll start in 2011 and let it run for 10 years.

``` ruby
mywp=Workpattern.new('My Workpattern',2011,10)
```

My **Workpattern** will be created as a 24 hour a day full working time.  Now it has to be told about the resting periods.  First the weekends.

``` ruby
mywp.resting(:days => :weekend)
```

then the days in the week have specific working and resting times using the *Workpattern.clock* method, although anything that responds to **hour** and **min** methods will do ...

``` ruby
mywp.resting(:days =>:weekday, :from_time=>Workpattern.clock(0,0),:to_time=>Workpattern.clock(8,59))
mywp.resting(:days =>:weekday, :from_time=>Workpattern.clock(12,0),:to_time=>Workpattern.clock(12,59))
mywp.resting(:days =>:weekday, :from_time=>Workpattern.clock(18,0),:to_time=>Workpattern.clock(23,59))
```

Now we have the working and resting periods setup we can just add 32 hours as minutes (1920) to our date.

``` ruby
mydate=DateTime.civil(2011,9,1,9,0)
result_date = mywp.calc(mydate,1920) # => 6/9/11@18:00
```

## Development

* Source hosted on [GitHub](http://github.com/callenb/workpattern).
* Direct questions and discussions to the [mailing list](http://groups.google.com/group/workpattern).
* Report issues on [GitHub Issues](http://github.com/callenb/workpattern/issues).
* Pull requests are very welcome, however I have never participated in Open Source so will be a bit slow as I am learning. Please be patient with me.  Please include spec and/or feature coverage for every patch,  and create a topic branch for every separate change you make.
* Advice, such as pointing out how I should really code in Ruby will be gratefully received.

## License

(The MIT License)

Copyright (c) 2012 

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
