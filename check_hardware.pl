#!/usr/bin/perl -w

use strict;
use warnings;

use lib::easy;
use Getopt::Long;

my $host ||= "o";
my $user ||= "0";
my $pass ||= "0";

my $exit_ok   = "0";
my $exit_warn = "1";
my $exit_crit = "2";
my $exit_unkn = "3"	;


my $ARG = GetOptions(
  "H=s" => \$host,
  "U=s" => \$user,
  "P=s" => \$pass
  )
  or die "UNKNOWN : Invalid Arguments! USAGE: IP -h <host> IPv6 -h <host> -u <user> -p <pass>\n";

if ( $host eq '0' | $user eq '0' | $pass eq '0' ) {
  print "UNKNOWN : Invalid Arguments! USAGE: IP -h <host> IPv6 -h <host> -u <user> -p <pass>\n";
  exit $exit_unkn;
}


my $WSMAN = DMTF::WSMAN::easy->new( ### Erstellen des Verbindungsobjekts

	"host"		=>	"$host",
	"port"		=>      "443",
        "user"		=>      "$user",
        "passwd"	=>      "$pass",
        "urlpath"	=>      "wsman",
        "proto"         =>	"https",
        "verbose"       =>      "0"

);

my $get1 = $WSMAN->get(

	"class"		=>	"DCIM_SystemView", ### Die Klasse aus welcher eine Instanz abgerufen werden soll
	"ns"		=>	"root/dcim", ### Namespace der die Klasse enthaelt
	"SelectorSet"	=>	{"InstanceID" => "System.Embedded.1"} ### Selektoren zur Auswahl einer konkreten Instanz aus der Klasse
);

my $dest = $WSMAN->close;

my $get2 = $WSMAN->get(

	"class"		=>	"DCIM_SystemString", ### Die Klasse aus welcher eine Instanz abgerufen werden soll
	"ns"		=>	"root/dcim", ### Namespace der die Klasse enthaelt
	"SelectorSet"	=>	{"InstanceID" => "System.Embedded.1#LCD.1#CurrentDisplay"} ### Selektoren zur Auswahl einer konkreten Instanz aus der Klasse
);

my $class_sysview = $get1->{"s:Body"}->{"n1:DCIM_SystemView"};
my $LCD = $get2->{"s:Body"}->{"n1:DCIM_SystemString"}->{"n1:CurrentValue"};
my $tag = $class_sysview->{"n1:ServiceTag"};


if ($class_sysview->{"n1:PrimaryStatus"} == 1){
  print "OK: $tag\n";
  exit $exit_ok;
}
  elsif($class_sysview->{"n1:PrimaryStatus"} == 2){
    print "WARNING: $LCD\n";
    exit $exit_warn;
  }
  elsif($class_sysview->{"n1:PrimaryStatus"} == 3){
    print "CRITICAL: $LCD\n";
    exit $exit_crit;
  }
  elsif($class_sysview->{"n1:PrimaryStatus"} == 0 && $class_sysview->{"n1:PowerState"} != 2){
    print "CRITICAL: POWER OFF\n";
    exit $exit_crit;
  }
  elsif($class_sysview->{"n1:PrimaryStatus"} == 0 && $class_sysview->{"n1:PowerState"} == 2){
    print "CRITICAL: No Data \n";
    exit $exit_crit;
  }

