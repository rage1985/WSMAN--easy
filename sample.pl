#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
use XML::Simple;
use lib::easy;
my $xml = new XML::Simple;

=pod

my $WSMAN = lib::easy->session( ### Erstellen des Verbindungsobjekts
	
	"host"		=>	"",
	"port"		=>      "443",
        "user"		=>      "nagios",	
        "passwd"	=>      "",
        "urlpath"	=>      "wsman",
        "proto"		=>	"https",
        "verbose"	=>	"0",
        "timeout"	=>	"1"

);

my $identify = $WSMAN->identify(); ### WSMAN-Provider auf der Zielmaschine prüfen

$WSMAN->close();
my $enum;

 $enum = $WSMAN->enumerate(

	"class"		=>	"DCIM_SystemView", ### Klasse die durchsucht werden solll
	"ns"		=>	"root/dcim", ### Namespace der die Klasse beinhaltet
	"optimized"	=>	"true", ### Automatische Enumeration 
	"maxelements"	=>	"512", ### Bestimmt die Anzahl der Rückgabeelemente in wsman:Items
        "Filter"	=>	"Select * from DCIM_View where InstanceID='DIMM.Socket.A1'", ### CQL Ausgabefilter
        "eprmode"       =>      "true" ### Endpoint Reference Mode
	"SelectorSet"	=>	{"__cimnamespace" => "root/dcim"} ### Selektoren zur Auswahl eines konkreten Elementes aus der Aufzählung
);
};



my $get = $WSMAN->get(

	"class"		=>	"DCIM_SystemString", ### Die Klasse aus welcher eine Instanz abgerufen werden soll
	"ns"		=>	"root/dcim", ### Namespace der die Klasse enthaelt
	"SelectorSet"	=>	{"InstanceID" => "System.Embedded.1#LCD.1#CurrentDisplay"} ### Selektoren zur Auswahl einer konkreten Instanz aus der Klasse
);



my $invoke = $WSMAN->invoke(

	 "class"		=>	"DCIM_SystemManagementService", ### Die Klasse die die Invoke Methode enthaelt
	 "InvokeClass"   =>	"IdentifyChassis", ### Die Invoke Methode selbst
         "SelectorSet"   =>	{"__cimnamespace" => "root/dcim", ### Selektoren für die Invoke Methode, sind der Doku delltechcenter.com/lc unter "Profiles" zu entnehmen
				 # "SystemCreationClassName" => "DCIM_ComputerSystem",
				 # "SystemName" => "srv:system",
				 # "CreationClassName" => "DCIM_SystemManagementService",
				 # "Name" => "DCIM:SystemManagementService"},

	 "Invoke_Input"	=>	{"IdentifyState" => "0"} ### Wert/Schluessel Paar für die Invoke Methode


# );
my $data = $xml->XMLin($enum);
print $WSMAN->to_list($enum, "n1:DCIM_SystemView");
print $WSMAN->to_list($enum, "p:Win32_Directory");
print "DELL LCD: $get->{'s:Body'}->{'n1:DCIM_SystemString'}->{'n1:CurrentValue'}\n";

=cut

exit 0;

