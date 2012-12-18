grailbird_updater
=================

For the most of the people who know me online, I've been dying to get a copy of my
Twitter archive from Twitter for forever. I was finally given one and decided
to write a quick script to keep my own archive up-to-date.

Turns out the contents in the archive are partial/trimmed API responses from the
Twitter API, so it is actually possible to drop a whole API response in there,
do some sorting and update the archive.

To run
```
./updater.rb /path/to/twitter/archive
```
