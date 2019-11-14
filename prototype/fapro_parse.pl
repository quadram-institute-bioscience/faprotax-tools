#!/usr/bin/env perl
use 5.012;
use warnings;
use Getopt::Long;
use Data::Dumper;
$Data::Dumper::Terse = 1;
use Term::ANSIColor qw(:constants);
use Storable;
use Carp qw(confess);
use FindBin qw($RealBin);

my $func_db = "$RealBin/db/FAPROTAX.txt";
my $output_data = "$RealBin/db/FAPROTAX.db";
my $opt_verbose;
my $opt_help;

my $_opt = GetOptions(
    'i|input-db=s' => \$func_db,
    'o|output-db=s'=> \$output_data,
    'v|verbose'    => \$opt_verbose,
    'h|help'       => \$opt_help,
);

usage() if (! defined $func_db or ! defined $output_data or defined $opt_help);

if (! -e "$func_db") {
    usage(" ERROR: Unable to find input FAPROTAX in <$func_db>.");
}
my $data = parse_db($func_db);

say GREEN Dumper $data->{taxa};
say RESET Dumper $data->{groups};
say RESET '';

store $data, "$output_data" || confess "Unable to write FAPROTAX db in <$output_data>\n"    ;
sub parse_db {
    my ($database) = @_;
    my $data;
    open my $I, '<', "$database" || confess "Unable to open FAPROTAX db, expected in <$database>\n";
    my $new_section;
    my $section_name;

    while (my $line = readline($I)) {
        next if ($line =~/^#/);
        chomp($line);
        
        if ($line eq '' or $line=~/^\s+$/) {
            $new_section = 1;
        } else {
            if ($new_section) {
                ($section_name, my $metadata) = $line =~/^(\w+)\s+(.*)$/;
                my @data = split /;\s*/, $metadata;
                say "\n",BOLD, $section_name,  "\n\t", CYAN,join('|', @data), RESET;
                for my $element (@data) {
                    my ($key, $value) = split /:/, $element;
                    $data->{groups}->{$section_name}->{metadata}->{$key} = $value;
                }
            } else {
                my ($taxon, $comment) = split /\s+#\s+/, $line;
                $comment .= '';
                
                if ($taxon =~/^(\w+):(.*)/) {
                    # Operation:
                    my $operation = $1;
                    my $group = $2;
                    say BOLD RED $operation, ":\t", RESET, $group, " (", scalar @{ $data->{groups}->{$group}->{members} }, " taxa)",  RED, ' to ', RESET, $section_name 
                         ;

                    if ($operation eq 'add_group') {
                        push( @{$data->{groups}->{$section_name}->{members}}, @{$data->{groups}->{$group}->{members}} );
                    } elsif ($operation eq 'subtract_group') {
                        #my %mother_group = map {$_ => 1} @{$data->{groups}->{$section_name}->{members}};
                        #my @subtracted  = grep {not $mother_group{$_}} @{$data->{groups}->{$group}->{members}};
                        #@{$data->{groups}->{$section_name}->{members}} = @subtracted;
                        @{ $data->{groups}->{$section_name}->{exclude_members} } = @{$data->{groups}->{$group}->{members} };
                    } elsif ($operation eq 'intersect_group') {
                        die " ERROR PARSING: Unimplemented (at the moment) <$operation> in:\n$line\n";
                    } else {
                        die " ERROR PARSING: Unknown operation <$operation> in:\n$line\n";
                    }
                } else {
                    say YELLOW $taxon, "\n\t", BLUE, $comment;

                    push(@{ $data->{groups}->{$section_name}->{members} }, $taxon);
                    push(@{ $data->{taxa}->{$taxon}} , $section_name);
                }
                
            }
            $new_section = 0;
        }



        
    }
    return $data;
}

sub usage {

    my $error = shift @_;
    say<<END;
  FAPROTAX DB BUILDER/PARSER
  ----------------------------------------------------------
  Usage: faproparse.pl [-i FAPROTAX.txt] [-o FAPROTAX.db]

  By default will parse ./db/FAPROTAX.txt and will produce a
  binary database in ./db/FAPROTAX.db.

  Options:
    -v, --verbose       Enable very verbose feedback
    -h, --help          Prints this message and exitß

END
  die "$error\n" if (defined $error);
  exit;
}
