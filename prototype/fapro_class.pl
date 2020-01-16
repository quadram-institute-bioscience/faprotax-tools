#!/usr/bin/env perl
use 5.012;
use warnings;
use Getopt::Long;
use Data::Dumper;
use Term::ANSIColor qw(:constants);
use Storable;
use Carp qw(confess);
use FindBin qw($RealBin);

my $opt_db = "$RealBin/db/FAPROTAX.db";
my $opt_verbose;
my $opt_help;
my $opt_taxonomy;
my $opt_debug;
my $DB;
my $_opt = GetOptions(
    'd|database=s' => \$opt_db,
    'debug'        => \$opt_debug,
    'v|verbose'    => \$opt_verbose,
    'h|help'       => \$opt_help,
    't|taxonomy'   => \$opt_taxonomy,
);

if (not defined $opt_taxonomy and defined $ARGV[0]) {
    $opt_taxonomy = shift @ARGV;
}

if (! -e "$opt_db") {
    die " FATAL ERROR: Unable to find FAPROTAX database in '$opt_db'.\n";
}

if (not defined $opt_taxonomy) {
    die " Please specify a taxonomy in ';' separated format\n";
}

eval {
    $DB = retrieve($opt_db);
};

die " FATAL ERROR:\n Unable to read FAPROTAX db ($opt_db).\n" if ($@);

$opt_taxonomy =~s/\?/\*/g;
my @ranks = split /[;,]/, $opt_taxonomy;

my %hits;

#say ">> ", join(', ', @ranks);
say Data::Dumper->Dump([\@ranks], [qw(ranks)]);;
for my $i ( keys %{ $DB->{taxa} }) {

    my $pattern = $i;
    $pattern=~s/\*/\.\*\?/g;
    if ($opt_taxonomy =~/$pattern/) {

        for my $hit ( @{ ${ $DB->{taxa} }{$i} }) {
            $hits{$hit}++;
        }

    }
}

for my $h (sort keys %hits) {
    say "== $h";
    say Dumper $DB->{groups}->{$h}->{members} if ($opt_debug);
    say join(', ', @{$DB->{groups}->{$h}->{members}}) if ($opt_verbose and not $opt_debug);
}
