#!/usr/bin/perl
use strict;
use Switch;
use Getopt::Long;
use Pod::Usage;

##################################################################################################
#
# Description:
#
#  The intention of this file is to create a file that containts one or more arithmetic operations
#  and its corresponing theia_terminal 'assertion' command
#  For example, a possible output for the script can be:
#  
#		iwrite 0 mul r1 r0 r0
#		write r0 0x30d
#		write r0 0x2bc
#		c
#		stop
#		assert r1 0x8578c
#
#  What the resulting script will do is:
#	 *multiply two numbers, 
#	 *store the multiplication result in  the 'r1' register
#	 *run the program
#	 *once the program is finished, assert 'r1' for the appropiate result value
#
##################################################################################################

my $OutputFileName      = "";
my $MaxIterations 		= 1;	#
my $ShowHelp      		= 0;	#Will display the program help and exit
my $PositiveNumbersOnly = 0;	#Test will not generate negative numbers as arithmetic operation arguments
my $ShowMan				= 0;
#Get the input arguments
GetOptions (
              "file=s"   			=> \$OutputFileName,      # string
              "iterations=i" 		=> \$MaxIterations,
              "help" 				=> \$ShowHelp,
              "positive_numbers"	=> \$PositiveNumbersOnly,
              "man"					=> \$ShowMan,
            ) ; #or pod2usage(2);


pod2usage(-exitval => 0, -verbose => 2) if $ShowMan;
pod2usage(1) if ($ShowHelp or $OutputFileName eq "");

###########################################################################################
#
#
#  										Main program
#
#
###########################################################################################

open FILE, ">$OutputFileName" or die "could not open file '$OutputFileName'\n";


print "Creating $MaxIterations iterations\n";
#We need to generate a file with instructions
my $GTMaxInterger   = 1000;
my @Operations = ("sub","mul");


for (my $i = 0; $i < $MaxIterations; $i++)
{
	my $OpIndex    = rand( $#Operations + 1 );
	my $Operation  = $Operations[ $OpIndex ];
	my $OperandA  = int(rand( $GTMaxInterger ));
	my $OperandB  = int(rand( $GTMaxInterger ));

	if ($PositiveNumbersOnly)
	{
		#Make sure numbers are actually positive
		$OperandA = abs( $OperandA );
		$OperandB = abs( $OperandB );
		#Make sure subtrations will not yiled to negative numbers
		if ($OperandA < $OperandB)
		{
			my $Temp 	= $OperandA;
			$OperandA 	= $OperandB;
			$OperandB 	= $Temp;
		}

	}
	my $Dest      = "r" . int(rand(8));
	my $Src1      = "r" . int(rand(8));
	my $Src0      = "r" . int(rand(8));
	printf FILE "iwrite 0 $Operation $Dest $Src1 $Src0\n";
	printf FILE "write %s 0x%x\n", $Src1, $OperandA;
	printf FILE "write %s 0x%x\n", $Src0, $OperandB;


	my $ExpectedResult = 0;

	switch ($Operation)
	{
	  case "sub" { $ExpectedResult = $OperandA - $OperandB  }
	  case "mul" { $ExpectedResult = $OperandA * $OperandB  }
	  case "add" { $ExpectedResult = $OperandA + $OperandB  }
	}

	printf FILE "c\n";
	printf FILE "stop\n";
	printf FILE "assert $Dest 0x%x\n\n\n",$ExpectedResult;
}

close FILE;
print "Random arithmetic tests succesfully created!\n";


__END__

=head1 NAME

sample - Using Getopt::Long and Pod::Usage

=head1 SYNOPSIS

NAME  -file [-iterations] [-positive_numbers] [-help] [-man]

=head1 OPTIONS

=over 8

=item B<-help>
    Print a brief help message and exits.

=item B<-man>
   Prints the manual page and exits.

=item B<-file>
       	Ouptfile.

=item B<-iterations>
    	Number of test cases generate.

=item B<-positive_numbers>
	Will only generate positive numbers


=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof.

=cut
