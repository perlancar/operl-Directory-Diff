use warnings;
use strict;
use Test::More;
use FindBin '$Bin';
use File::Path 'remove_tree';
BEGIN { use_ok('Directory::Diff') };
use Directory::Diff qw/get_only get_diff ls_dir/;

my %dir1 = ("file" => 1, "dir/" => 1, "dir/file" => 1);
my %dir2 = ("dir/" => 1, "dir2/" => 1);

#             _                  _       
#   __ _  ___| |_     ___  _ __ | |_   _ 
#  / _` |/ _ \ __|   / _ \| '_ \| | | | |
# | (_| |  __/ |_   | (_) | | | | | |_| |
#  \__, |\___|\__|___\___/|_| |_|_|\__, |
#  |___/        |_____|            |___/ 
#

my %got_only = get_only (\%dir1, \%dir2);
my %only = ("file" => 1, "dir/file" => 1);
#print join ", ", (keys %got_only), "\n";
ok ((keys %got_only) == 2, "correct number of entries from get_only");
my $same_keys = 0;
for my $k (%only) {
#    print "$k\n";
    if ($got_only{$k}) {
        $same_keys++;
    }
}
ok ($same_keys == 2, "expected keys from get_only");

%dir1 = ("dir/" => 1, "dir/dir/" => 1, "dir/dir/file" => 1, "dir2/" => 1);
%dir2 = ("dir2/" => 1);

%got_only = get_only (\%dir1, \%dir2);
ok (keys %got_only == 3, "correct number of entries for sub-sub-directory");
%only = ("dir/" => 1, "dir/dir/" => 1, "dir/dir/file" => 1);
$same_keys = 0;
for my $k (%only) {
#    print "$k\n";
    if ($got_only{$k}) {
        $same_keys++;
    }
}
ok ($same_keys == 3, "expected keys from get_only");


# The new and old directories.

my $old_dir = "$FindBin::Bin/test_old_dir";
my $new_dir = "$FindBin::Bin/test_new_dir";
my @dirs = ($old_dir, $new_dir);
rm_mk_dirs (@dirs);

# Test "get_diff" on simple files.

create_file ("bananas", $old_dir, "yes");
create_file ("bananas", $new_dir, "yes");

create_file ("nuts", $old_dir, "yes");
create_file ("nuts", $new_dir, "no");

my %diff = run_diff ($old_dir, $new_dir);

ok (keys %diff == 1, "Correct number of results");
ok ($diff{nuts}, "Detected simple difference");

rm_mk_dirs (@dirs);

# Test "get_diff" on a subdirectory.

my $old_boo = "$old_dir/boo";
my $new_boo = "$new_dir/boo";
mkdir $old_boo or die $!;
mkdir $new_boo or die $!;

create_file ("bananas", $old_boo, "yes");
create_file ("bananas", $new_boo, "no");

%diff = run_diff ($old_dir, $new_dir);

ok (keys %diff == 1, "Correct number of results");
ok ($diff{"boo/bananas"}, "Detected simple difference");

rmdirs (@dirs);

done_testing ();

exit;

sub create_file 
{
    my ($file_name, $dir_name, $contents) = @_;
    my $path = "$dir_name/$file_name";
    die "$path exists" if -f $path;
    open my $output, ">:encoding(utf8)", $path or die "$path: $!";
    print $output $contents;
    close $output or die $!;
}

sub rmdirs
{
    for (@_) {
	(-d $_) && remove_tree ($_);
        die if -d $_;
    }
}

sub mkdirs
{
    for (@_) {
        die if -d $_;
        mkdir $_ or die $!;
    }
}

sub rm_mk_dirs
{
    rmdirs (@_);
    mkdirs (@_);
}

sub run_diff
{
    my ($dir1, $dir2) = @_;
    my %dir1_ls = ls_dir ($dir1);
    my %dir2_ls = ls_dir ($dir2);
    return get_diff ($dir1, \%dir1_ls, $dir2, \%dir2_ls);
}

# Local variables:
# mode: perl
# End:
