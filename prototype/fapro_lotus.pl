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
my $opt_debug;
my $opt_help;
my $opt_input_dir;
my $opt_outdir;
my $DB;
my $taxonomy_file;
my $_opt = GetOptions(
    'i|lotusdir=s' => \$opt_input_dir,
    'o|outdir=s'   => \$opt_outdir,
    't|taxon=s'    => \$taxonomy_file,
    'd|database=s' => \$opt_db,
    'v|verbose'    => \$opt_verbose,
    'd|debug'      => \$opt_debug,
    'h|help'       => \$opt_help,
);

# Find input directory
if (not defined $opt_input_dir and defined $ARGV[0]) {
    verbose("Assuming $ARGV[0] to be -i $ARGV[0]");
    $opt_input_dir = shift @ARGV;
}
if (! -d "$opt_input_dir") {

    usage();
    die " FATAL ERROR: Input directory not found <$opt_input_dir>.\n" if (defined $opt_input_dir);
    exit();
}

# OUTPUT directory
if (not defined $opt_outdir) {
    $opt_outdir = "$opt_input_dir/function";
    if (! -d "$opt_outdir") {
        mkdir "$opt_outdir" || die "FATAL ERROR:\n Unable to create output directory $opt_outdir\n"
    } else {
        verbose("Output directory found: $opt_outdir")
    }
}
# Check DB presence
if (! -e "$opt_db") {
    die " FATAL ERROR: Unable to find FAPROTAX database in '$opt_db'.\n";
} else {
    verbose("FAPROTAX DB:  $opt_db");
}



eval {

    $DB = retrieve($opt_db);
};

die " FATAL ERROR:\n Unable to read FAPROTAX db ($opt_db).\n You can set it with -d PATH\n" if ($@);

# TAXONOMY FILE

my $otutable_file = "$opt_input_dir/OTU.txt";
if (not defined $taxonomy_file) {
  if (-e "$opt_input_dir/hiera_RDP.txt") {
      $taxonomy_file = "$opt_input_dir/hiera_RDP.txt";

  } elsif (-e "$opt_input_dir/hiera_BLAST.txt") {
      $taxonomy_file = "$opt_input_dir/hiera_BLAST.txt";
  } else {
      die " FATAL ERROR:\n Unable to find taxonomy hierarchy in $opt_input_dir: hiera_RDP.txt / hiera_BLAST.txt\nYou can specify it with --taxon FILE\n";
  }
}
verbose("Taxonomy:     $taxonomy_file");

# OTUTABLE FILE

if (-e "$otutable_file") {
    verbose("OTU table:    $otutable_file");
} else {
    die " FATAL ERROR:\n Unable to find OTU table in $otutable_file\n";
}

# Get OTU-> taxonomy from hiera_x.txt
my $otu_taxonomy = load_taxonomy("$taxonomy_file");
# Create OTU -> function
my $otu_classes = classify_otus($otu_taxonomy);

print_classes($otu_taxonomy, $otu_classes, "$opt_outdir/OTU_functions.txt");
print_otutable($otu_classes, $otutable_file, "$opt_outdir/otutab.functions.tsv");

sub print_otutable {

    my ($otu_classes, $otutable_file, $output) = @_;
    verbose("Preparing Functional OTU table: $output");
    my $O;
    if (not open  $O, '>', "$output") {
        die " FATAL ERROR:\n Unable to write to \"$output\".\n";
    }

    my $I;
    if (not open $I, '<', "$otutable_file") {
        die " FATAL ERROR:\n Unable to read OTU table \"$otutable_file\".\n";
    }
    my $c = 0;
    my @samples;
    my $counts;
    while (my $l = readline($I) ) {
        $c++;
        chomp($l);
        if ($c == 1) {

            (undef, @samples) = split /\t/, $l;
            say {$O} "Class\t", join("\t", @samples);
        } else {

            my ($otu, @sample_counts) = split /\t/, $l;
            my @classes = undef;
            if (defined ${ $otu_classes }{$otu}) {
                @classes = split /;/, ${ $otu_classes }{$otu}
            } else {
                    next
            }
            for my $class (@classes) {
                next unless ($class);
                for (my $i = 0; $i <= $#samples; $i++) {
                    my $sample_name = $samples[$i];

                    if ($counts->{$class}->{$sample_name}) {
                        $counts->{$class}->{$sample_name} += $sample_counts[$i];
                    } else {
                        $counts->{$class}->{$sample_name} = $sample_counts[$i];
                    }

                }

            }

        }
    }

    verbose("OTU table parsed: $c lines");
    for my $class (sort keys %{ $counts }) {
        print {$O} $class, "\t";
        for my $sample (@samples) {
            print {$O}  $counts->{$class}->{$sample};
            if ($sample eq $samples[-1]) {
                print {$O} "\n";
            } else {
                print {$O} "\t";
            }
        }

    }
}

sub print_classes {

    my ($tax, $class, $out) = @_;
    verbose("Preparing Functional annotation: $out");
    my $O;
    if (not open  $O, '>', "$out") {
        die " FATAL ERROR:\n Unable to write to \"$out\".\n";
    }
    say {$O} "#OTU\tClasses\tTaxonomy";
    for my $otu (sort keys %{ $tax }) {
        my $class = ${ $class }{ $otu} ? ${ $class }{ $otu} : 'N/A';
        say {$O} "$otu\t", $class, "\t", ${ $tax }{$otu};

    }
}
sub classify_otus {
    my ($otu_hash) = @_;
    my %classification;
    debug("[classify_otus]");
    for my $otu (sort keys %$otu_hash) {
        my $tax = $$otu_hash{$otu};
        my %hits;
        debug("$otu -> $tax");
        for my $i ( keys %{ $DB->{taxa} }) {
            my $pattern = $i;
            $pattern=~s/\*/\.\*\?/g;
            if ($tax =~/$pattern/) {
                for my $hit ( @{ ${ $DB->{taxa} }{$i} }) {
                    $hits{$hit}++;
                }
            }
            debug(" ->$tax =~/$pattern/ ? ");
        }
        for my $h (sort keys %hits) {
            $classification{$otu} .= "$h;";
        }

    }
    return \%classification;
}
# my @ranks = split /;/, $opt_taxonomy;

# my %hits;
# for my $i ( keys %{ $DB->{taxa} }) {

#     my $pattern = $i;
#     $pattern=~s/\*/\.\*\?/g;
#     if ($opt_taxonomy =~/$pattern/) {

#         for my $hit ( @{ ${ $DB->{taxa} }{$i} }) {
#             $hits{$hit}++;
#         }

#     }
# }

# for my $h (sort keys %hits) {
#     say "== $h";
#     say Dumper $DB->{groups}->{$h}->{members};
# }

sub load_taxonomy {
    my ($file) = @_;
    debug("[load_taxonomy]: $file");
    my $I;
    my %taxonomy;
    if (not open  $I, '<', "$file") {
        return die " FATAL ERROR:\n Unable to open file \"$file\".\n";

    }

    # OTU      Domain  Phylum  Class   Order   Family  Genus   Species
    # OTU_3   Bacteria        Bacteroidetes   Bacteroidia     Bacteroidales   S24-7   ?       ?
    # OTU_4   Bacteria        Bacteroidetes   Bacteroidia     Bacteroidales   Rikenellaceae   ?       ?
    # OTU_2   Bacteria        Bacteroidetes   Bacteroidia     Bacteroidales   Porphyromonadaceae      Parabacteroides ?

             #domain     phylum     class order family     genus species    OTU
    my $line_counter = 0;
    while (my $line = readline($I)  ) {
        $line_counter++;
        chomp($line);
        my @fields = split /\t/, $line;
        my $format = 'blast';

        if ($line_counter == 1) {
            if ($fields[0] eq 'OTU' and $fields[1] eq 'Domain' and $fields[-1] eq 'Species') {
                verbose("OTU taxonomy: valid header ($file)");
            } elsif ($fields[0] eq 'domain' and $fields[-1] eq 'OTU') {
                $format = 'rdp';
                verbose("OTU taxonomy: probably valid header ($file)");
            } else {
                die " FATAL ERROR:\n OTU taxonomy ($file) not valid: line 1 has a bad header\n";
            }
        } else {
            last if ($#fields != 7);
            if ($format eq 'blast') {
                my $otu = shift @fields;
                $taxonomy{ $otu} = join(";", @fields);
            } elsif ($format eq 'rdp') {
                my $otu = pop @fields;
                $taxonomy{ $otu} = join(";", @fields);                
            } 
        }
    }
    verbose("OTU taxonomy: $line_counter lines parsed");
    return \%taxonomy;
}
sub usage {
    say STDERR<<END;

  ------------------------------------------------------------
  Functional classification of 16S experiments
  ------------------------------------------------------------

  This program loads the output directory created by
  Lotus (Hildebrand 2014) and creates a file with the
  functional annotation of OTUs.

  -i, --lotusdir
                   Input directory (i.e. the output of
                   Lotus)

  -o, --outdir
                   Output directory (def: input_dir/function)
  -d, --database
                   FAPROTAX database as produced by
                   fapro_parse.pl (def: ./db/FAPROTAX.db)
END
}

sub verbose {
    my $message = shift @_;
    say STDERR "# $message" if ($opt_verbose or $opt_debug);
}

sub debug {
    my $message = shift @_;
    say STDERR "~ $message" if ($opt_debug);
}
