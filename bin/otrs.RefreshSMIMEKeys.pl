#!/usr/bin/perl
# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
# --
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);
use lib dirname($RealBin) . '/Kernel/cpan-lib';
use lib dirname($RealBin) . '/Custom';

use Getopt::Std;

use Kernel::System::ObjectManager;

# get options
my %Opts;
getopt( 'd', \%Opts );

if ( $Opts{h} ) {
    print "otrs.RefreshSMIMEKeys.pl - fix SMIME certificates private keys and"
        . " secrets filenames\n";
    print "Copyright (C) 2001-2019 OTRS AG, https://otrs.com/\n";
    print "usage: otrs.RefreshSMIMEKeys.pl -d <DETAILS> (short|long) [-f (force to execute even"
        . " if SMIME is not enabled in SysConfig)]  \n";
    exit 1;
}
my %Options;

$Options{Details} = 'Details';
if ( $Opts{d} && lc $Opts{d} eq 'short' ) {
    $Options{Details} = 'ShortDetails';
}

# create object manager
local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Kernel::System::Log' => {
        LogPrefix => 'OTRS-otrs.RefreshSMIMEKeys.pl',
    },
    'Kernel::System::Crypt' => {
        CryptType => 'SMIME',
    },
);

# check for force option to activate SMIME support in SysConfig during the execution of this script
if ( exists $Opts{f} ) {
    $Kernel::OM->Get('Kernel::Config')->Set(
        Key   => 'SMIME',
        Value => 1,
    );
}

if ( !$Kernel::OM->Get('Kernel::System::Crypt') ) {
    print "NOTICE: No SMIME support!\n";

    my $SMIMEActivated = $Kernel::OM->Get('Kernel::Config')->Get('SMIME');
    my $CertPath       = $Kernel::OM->Get('Kernel::Config')->Get('SMIME::CertPath');
    my $PrivatePath    = $Kernel::OM->Get('Kernel::Config')->Get('SMIME::PrivatePath');
    my $OpenSSLBin     = $Kernel::OM->Get('Kernel::Config')->Get('SMIME::Bin');

    if ( !$SMIMEActivated ) {
        print "SMIME is not activated in SysConfig!\n";
    }
    elsif ( !-e $OpenSSLBin ) {
        print "No such $OpenSSLBin!\n";
    }
    elsif ( !-x $OpenSSLBin ) {
        print "$OpenSSLBin not executable!\n";
    }
    elsif ( !-e $CertPath ) {
        print "No such $CertPath!\n";
    }
    elsif ( !-d $CertPath ) {
        print "No such $CertPath directory!\n";
    }
    elsif ( !-w $CertPath ) {
        print "$CertPath not writable!\n";
    }
    elsif ( !-e $PrivatePath ) {
        print "No such $PrivatePath!\n";
    }
    elsif ( !-d $PrivatePath ) {
        print "No such $PrivatePath directory!\n";
    }
    elsif ( !-w $PrivatePath ) {
        print "$PrivatePath not writable!\n";
    }
    exit 1;
}

my $CheckCertPathResult = $Kernel::OM->Get('Kernel::System::Crypt')->CheckCertPath();
print $CheckCertPathResult->{ $Options{Details} };

exit !$CheckCertPathResult->{Success};