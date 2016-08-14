Abelard feed archiver
=====================

Purpose
-------

Blogs and news sites can disappear.

This tool can make and maintain an archive of posts and comments,
which can be efficiently tracked and shared using git, so there is
no longer a single copy that can be deleted.

It is not a feed aggregator, or viewer, or publisher. 
There is only very rudimentary
provision for actually using the archived data--the priority is
retaining it.

It can handle atom or rss feeds to create or update an archive, but as
the feeds usually carry only recent posts, that is not sufficient to
make a complete archive of an exisiting site.  Therefore it can also
handle the export formats produced by Blogger or Wordpress.  Once an
archive has been created from a site's history that way, the public
feeds are the easiest way of updating it.

Status
------

The code is new and experimental; it works on the feeds I have tested
it with, but could easily fail on unexpected input. Also the error-handling
is minimal, so it's of limited use unless you are prepared to dig into
the code when it falls over.

In particular, there is nothing that works with the comment files. They
are created in the archive, so you have them, but other than looking at the
files, you cannot use them.

It builds a ruby gem, and works on Linux.  I'm not sure if it would be
possible to get it to work on Windows, but I haven't tried.

The information in the export file is all retained in the archive. It
is possible that that includes some sensitive data; I didn't see any in
my testing but I don't make any guarantees.  You should check it before
sharing or publishing your archive.

Usage
-----

The tools are invoked through the wrapper binary "abelard"

* abelard load -f \<feed-file\> directory
* abelard load -n \<url\> directory
* abelard load \<config-block\>

create files for posts and comments in directory, working from either
a file, a url, or a the urls configured for a feed

* abelard list directory

list the post titles and dates in a directory

* abelard dump directory

create a feed file to standard out including all posts and comments in a 
directory

* abelard web

Start a mini-webserver running on port 4567 to serve the configured feeds


The load command writes posts and comments, one per file, into the 
specified directory.  The intention is that each such directory can be
made into a git archive and shared. 

If a post is modified, the new version will overwrite the old. Export
files, posts feeds and comment feeds can all be extracted and dumped in
the same manner.

Configuration
-------------

The commands can use a configuration file "blogfeeds.yaml", which for now
has to be created and edited by hand.

The YAML format file has a block for each blog.

<code>
shortname:
  dest: directoryname
  urls:
    - somefeedurl
    - someotherfeedurl
</code>

There will probably be two urls, one for posts and one for comments, but
one is OK if there are no comments (or you don't care about comments), and
more than two would work.

The load command without -f or -n just takes the shortname and loads each
url into the dest directory.

The web command runs up a little sinatra web server that lists the feeds
in the config and recreates a complete posts feed for each one.


