#!/usr/bin/perl

use strict;
use Getopt::Long;

my ($directory, $output_directory, $help);

GetOptions( 'dir=s' => \$directory,
			'out_dir=s' => \$output_directory,
			'help' => \$help);
			
if(!$directory or $help)
{
	printHelp();
	exit(0);
}

$output_directory = $directory unless $output_directory;

print "Looking for files in $directory\n";
my @files = <$directory/*>;
print "Found " . @files . " files to process...\n";

foreach my $file (@files)
{
	print "Sorting $file...\n";
	my $sorted_data = sortLines($file);
	printSortedData($output_directory, $file, $sorted_data);
}

exit(0);


### Subroutines ###

sub printHelp
{
	print <<HELP;

perl rgd-gff-sort.pl

Purpose:
Sort GFF3 files, required by InterMine parser
Will overwrite files unless output directory is specified

Arguments:
 --dir		Input Directory
 --out_dir		Output Directory [OPTIONAL]
 --help			Print this message
HELP
}

sub sortLines
{
	my $file = shift;
	
	my %data;
	open(my $IN, '<', $file) or die("unable to open $file\n");
	while(<$IN>)
	{
		next if /^#/; #ignore comments
		my $feature = findFeature($_);
		
		$data{$feature} = () unless( exists $data{$feature} );
		push(@{$data{$feature}}, $_);
	}
	close $IN;
	return \%data;
}

sub findFeature
{
	my $line = shift;
	my @data = split(/\t/);
	return $data[2];
}

sub printSortedData
{
	my ($output_directory, $file, $sorted_data) = @_;
	
	$file = $1 if $file =~ /[\d\D]+?([\\\/][\w+\.]+?\.gff3)/i;
	
	my $outfile = $output_directory . $file;
	print "Print data to $outfile...\n";
	open(my $OUT, '>', $outfile) or die("unable to open $outfile\n");
	
	my @order = qw(gene mRNA exon CDS 3UTR 5UTR);
	my @features = keys(%$sorted_data);
	print "printing features: @features\n";
	print "in order: @order\n";
	foreach my $feature (@order)
	{
		foreach my $lines ($$sorted_data{$feature})
		{
			foreach my $line (@$lines)
			{
				print $OUT $line;
			}
		}
	}
	close $OUT;
}