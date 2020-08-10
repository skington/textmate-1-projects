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

# Generate symlinks.
my $num;
for my $document (@$documents) {
    my $path_prefix = $project_dir . '/' . $generate_prefix->($num++);
    if ($document->{filename}) {
        my ($leafname) = ($document->{filename} =~ m{ / ( [^/]+ ) $}x);
        my $true_path = $dir->file($document->{filename});
        symlink($true_path, $path_prefix . $leafname);
    } elsif (my $source_dir_name = $document->{sourceDirectory}) {
        my $symlink_dir_name = $path_prefix . $document->{name};
        mkdir($symlink_dir_name);
        my $source_dir = $dir->subdir($source_dir_name);
        opendir(my $dh, $source_dir)
            or die "Couldn't read source directory $source_dir: $OS_ERROR";
        file:
        while (my $file = readdir($dh)) {
            next file if $file =~ /^[.]/;
            symlink($source_dir->file($file), $symlink_dir_name . '/' . $file)
                or die "Couldn't create symlink: $OS_ERROR";
        }
    }
}

__DATA__
use Data::Dumper;
local $Data::Dumper::Indent = 1;
local $Data::Dumper::Sortkeys = 1;
local $Data::Dumper::Terse = 1;
print Dumper($data->as_perl);