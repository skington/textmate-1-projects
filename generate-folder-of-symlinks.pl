#!/usr/bin/env perl
# Extract the files and directories belonging to the probject and create
# symlinks to them in an appropriate directory.
# We'll ignore details about which files are open etc. - that's much less
# important than which files are in the project and in which order.

use strict;
use warnings;
use English qw(-no_match_vars);

use Mac::PropertyList;

# Sanity-check: make sure we're givne a reasonable-looking file.
my $file = shift or die "Syntax: $PROGRAM_NAME <file>\n";
-e $file or die "No such file $file";
my $data = Mac::PropertyList::parse_plist_file($file)
    or die "Couldn't parse project: $OS_ERROR";
my $project_dir = $file =~ s{ [.]tmproj }{.tm2proj}xr || $file . '.tm2proj';
if (!-e $project_dir) {
    mkdir($project_dir) or die "Couldn't create $project_dir: $OS_ERROR";
}

# Find the documents.
my $documents = $data->{documents}->as_perl;
my $num_documents = scalar @$documents;
for my $document (@$documents) {
    my ($leafname, $true_path);
    if ($document->{filename}) {
        $true_path = $document->{filename};
        ($leafname) = ($document->{filename} =~ m{ / ( [^/]+ ) $}x);
    } elsif ($document->{sourceDirectory}) {
        $true_path = $document->{sourceDirectory};
        $leafname = $document->{name};
    }
    print "$leafname: $true_path\n";
}

__DATA__
use Data::Dumper;
local $Data::Dumper::Indent = 1;
local $Data::Dumper::Sortkeys = 1;
local $Data::Dumper::Terse = 1;
print Dumper($data->as_perl);