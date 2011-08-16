PFTT
====
A work-in-progress port of https://github.com/ostc/pftt in ruby.

Will provide functional and performance testing of PHP under different environemnts in an 
automated manner.

Supported Factors
=================

This tool will provide an automated methodology for testing PHP in many different combinations 
of factors, the types of which are listed below.

Hosts
-----

Will support both local and remote hosts, at first executing remote commands via SSH, but also 
able to support other protocols (such as WinRM) since this support is provided in an abstract manner.

 - Windows (XP SP3 and later)*
 - Posix (with pre-built PHP binaries)

Middleware
----------

 - Command Line Interface*
 - Over HTTP*
   - IIS*
     - FastCGI*
     - Other SAPIs*
   - Apache
     - ModPHP*
     - Other SAPIs*

PHP Builds
----------

 - Pre-built binaries from windows.php.net (snaps, pre-releases, and releases)*
 - Post-built binaries
   - Windows
   - Linux

Functional Testing
==================

We use an extended subset of phpt file format, and will eventually implement the entire format 
(missing right now are POST, ENV, and REDIRECTTEST, which we will add support for once we get 
automation complete).

The extension to this format is that we can pre-replace special PHP Constants (all-caps, wrapped 
in 3 underscores), which we do in order to tell the script where to access files (See Filesystem 
Contexts below), as well as a special --PFTT-- section to inform PFTT of special setup 
instructions, such as which files to populate alongside the script, etc.

Filesystem Contexts
-------------------

Where the script is and what it is trying to access can (especially on Windows) affect the 
outcome of tests that access the filesystem in various ways. Because of this, we will execute 
tests in different contexts to verify functionality across these contexts.

 - Local Filesystem
 - Symlinked directories
 - DFS volumes
 - UNC volumes
 - Etc.


Performance Testing
===================

We can deploy a PHP application (such as Wordpress, MediaWiki) to a deployed Test Bench (with 
HTTP-based middleware) and use WCAT to gauge its performace. This is handled through our multiple 
host control mechanism, which we can use to install the test bench on one machine while using 
another machine to launch a performance test that uses still more machines.
