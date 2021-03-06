## Workpattern v0.6.0 ( 25 Feb, 2021) ##

I stopped keeping this Changelog file update back when v0.5.0 was realeased on 19 Oct 2016 and now it is 10Feb 2021 and I'm playing catch-up.
I have created the following set of bullet point changes by going through my commit messages, the quality of which varies greatly.  
A lot of the effort has been on making the code easier to read as it was a real mess.
Here is a chronological take on what I have been doing.

* removed test warnings by surrounding ambiguous negatives with parenthesis
* I think a bug was fixed by changing #wee_total and #total to just an attr_writer
* removed some duplicated code
* replaced a number of literals with constants which I put in their own file
* made a lot of the code easier to read, such as extracting to a method with a sensible name or renaming existing ones
* Workpattern is now tested on Ruby 1.9.3, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, ruby-head, jruby-19mode & jruby-head
* Created a Day class to remove the complexity from Week so Week deals with weeks and Day with a day
* My Clock class was replaced by Time or Date objects in all tests.  Clock only used for internal stuff now.
* Switched to sorted_set rubygem after the SortedSet class was removed from Ruby in v3.x.
* Workpattern now works with ruby 3.0.1dev
* added Contributor Covenant Code of Conduct

## Workpattern v0.5.0 ( Oct 19, 2016) ##

* Workpattern now handles Timezones.  It changes the date into UTC, does the calculation and then changes it back * Barrie Callender
* Removed Day class and associated tests as it is no longer used * Barrie Callender
* Reviewed the README and removed a lot of cruft and also updated it a little to demonstrate features * Barrie Callender
* Hid documentation unless it was part of the public api * Barrie Callender
* Used Rubocop to help me be more consistent.  I ignored some of the offences to do with long lines/methods and classes * Barrie Callender
* Code makes use of Time objects where it use to use DateTime.  Time comes with a Timezone * Barrie Callender
* Rewrote/refactored methods in the Week class - which needs refactoring into new classes * Barrie Callender
* Removed rubyforge_project from workpattern.gemspec * Barrie Callender
* Added homepage & required_ruby_version to workpattern.gemspec * Barrie Callender
* Added versions to test in Travis CI to include 1.9.3, 2.0.0, 2.1.0, 2.1.9, 2.2.0, 2.2.5, 2.3.0 & 2.3.1 * Barrie Callender
* Dealt with Travis CI issue with version of bundler * Barrie Callender
* Removed config directory & contents * Barrie Callender
* Changed Description * barrie Callender
* Specified minitest ~> 5.4.3 due to an issue I no longer recall * Barrie Callender
* Hid all the documentation apart from public api * Barrie Callender
* improved the README.md (IMHO) * Barrie Callender

## Workpattern v0.4.0 ( May 23, 2014)  ##

* Updated Week class to use bits and removed Day and Hour class as a consequence * Barrie Callender *
* This resulted in a performance improvement and some new tests

## Workpattern v0.3.6 (Mar 25, 2014)  ##

* total minutes of week is zero when short week starting after Sunday (#17) * Barrie Callender *
* Subtracting starting from top of the hour and last minute is non working (#18) * Barrie Callender *
* Refactorings intended to make the code easier to read and easier to change - still more to do * Barrie Callender *

## Workpattern v0.3.5 (Sep 30, 2013)  ##

* License missing from gemspec (#16) * Barrie Callender *
* Removed Gemfile.lock from git and updated .gitignore to the bundler defaults * Barrie Callender *

## Workpattern v0.3.4 (Sep 27, 2013)  ##

* diff doesn't calculate properly from working to resting day (#15) * Barrie Callender *

## Workpattern v0.3.3 (Sep 23, 2013)  ##

* Failed to subtract 1 minute from end of resting hour (#12) * Barrie Callender *
* Failed to add minutes starting from a resting period in a patterned hour (#13) * Barrie Callender *
* Failed to subtract the exact amount of minutes from a patterned hour (#14) * Barrie Callender *
* The two tests no longer fail with Ruby 2.0 (#11) * Barrie Callender *


## Workpattern v0.3.2 (Mar 14, 2013)  ##

* Changed methods on Hour module so as to not clash with Rails (#10) * Barrie Callender *
* Applied DRY principle to workpattern method in Workpattern class * Barrie Callender *
* Removed file from emacs backup * Barrie Callender *

## Workpattern v0.3.1 (Oct 14, 2012)  ##

* RDOC documentation not right on rubydoc.info (#5) * Barrie Callender *

## Workpattern v0.3.0 (Jul 19, 2012)  ##

* incomplete tests for week (#2) * Barrie Callender *
* getting wrong time when hour had exactly the right number of minutes (#9) * Barrie Callender *
* jruby-19mode failed with SystemStackError: stack level too deep  (#8) * Barrie Callender *
* midnight flag should override hour and minutes  (#7) * Barrie Callender *
* available minutes not calculating correctly for a time of 00:01 (#6) * Barrie Callender *

## Workpattern v0.2.0 (May 31, 2012)  ##

*   Rewritten from scratch effectively first version * Barrie Callender *
* Please discard any version of Workpattern before this - some poor souls may have come across v0.1.0. - sorry! * Barrie Callender *
