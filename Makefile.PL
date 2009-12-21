use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::phpBB::Poster',
    VERSION_FROM      => 'lib/WWW/phpBB/Poster.pm', # finds $VERSION
    PREREQ_PM         => {
	DBI=>0,
	Digest::MD5=>0
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/phpBB/Poster.pm', # retrieve abstract from module
       AUTHOR         => 'Andrew Pavlutkin <skazo4nik@gmail.com>') : ()),
);
