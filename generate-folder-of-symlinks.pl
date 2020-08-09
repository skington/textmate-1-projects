#!/usr/bin/env perl
# Extract the files and directories belonging to the probject and create
# symlinks to them in an appropriate directory.
# We'll ignore details about which files are open etc. - that's much less
# important than which files are in the project and in which order.

use strict;
use warnings;
use feature qw(say signatures);
no warnings qw(experimental::signatures);

use English qw(-no_match_vars);

use Mac::PropertyList;
use Path::Class;

# Sanity-check: make sure we're givne a reasonable-looking file.
my $filename = shift or die "Syntax: $PROGRAM_NAME <file>\n";
-e $filename or die "No such file $filename";
my $dir = Path::Class::file($filename)->parent->absolute;
$dir->resolve;
my $data = Mac::PropertyList::parse_plist_file($filename)
    or die "Couldn't parse project: $OS_ERROR";
my $project_dir
    = $filename =~ s{ [.]tmproj }{.tm2proj}xr || $filename . '.tm2proj';
if (!-e $project_dir) {
    mkdir($project_dir) or die "Couldn't create $project_dir: $OS_ERROR";
}

# Find the documents.
my $documents = $data->{documents}->as_perl;
my $num_documents = scalar @$documents;
my $format = '%0' . length($num_documents) . 'd ';
my $generate_prefix = sub ($num) {
    sprintf($format, $num);
};
my $num;
for my $document (@$documents) {
    # Work out what we're symlinking to as what.
    my ($leafname, $relative_path);
    if ($document->{filename}) {
        $relative_path = $document->{filename};
        ($leafname) = ($document->{filename} =~ m{ / ( [^/]+ ) $}x);
    } elsif ($document->{sourceDirectory}) {
        $relative_path = $document->{sourceDirectory};
        $leafname = $document->{name};
    }

    # Generate a name for this symlink.
    ### TODO: do this nicer.
    my $true_path = $dir->file($relative_path);
    symlink($true_path,
        $project_dir . '/' . $generate_prefix->($num++) . $leafname);
}

__DATA__
use Data::Dumper;
local $Data::Dumper::Indent = 1;
local $Data::Dumper::Sortkeys = 1;
local $Data::Dumper::Terse = 1;
print Dumper($data->as_perl);