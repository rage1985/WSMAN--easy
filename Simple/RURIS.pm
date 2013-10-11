package WSMAN::Simple::RURIS;

#use WSMAN::Simple;
require Exporter;
require DynaLoader;
use vars qw( @ISA $VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA = qw(Exporter);

@EXPORT_OK = qw(			URI_SOAP
					URI_ADDR
					URI_WSMAN1
					URI_CIMBIND
					URI_WSMID

					URI_ENUM
					URI_GET
					URI_PUT
					URI_FAULT

					URI_DCIM
					URI_CIM
					URI_WMI
					URI_WMICIMV2
					URI_CIMV2
					URI_WINRM
					URI_WSMAN
					URI_SHELL
					URI_WIN32
					URI_VMware

					URI_ASSOCFI
					URI_FILTER

);
%EXPORT_TAGS = (
		namespaces => [qw(
					URI_SOAP
					URI_ADDR
					URI_WSMAN1
					URI_CIMBIND
					URI_WSMID
				)],
		action => [qw(
					URI_ENUM
					URI_GET
					URI_PUT
					URI_FAULT
				)],
		oem => [qw(
					URI_DCIM
					URI_CIM
					URI_WMI
					URI_WMICIMV2
					URI_CIMV2
					URI_WINRM
					URI_WSMAN1
					URI_SHELL
					URI_WIN32
					URI_VMware
				)],
		dialect => [qw(
					URI_ASSOCFI
					URI_FILTER
				)]
		);

###Globale XML Namespaces###
use constant URI_SOAP 	=>	"http://www.w3.org/2003/05/soap-envelope"; 
use constant URI_ADDR 	=>	"http://schemas.xmlsoap.org/ws/2004/08/addressing";
use constant URI_WSMAN1	=> 	"http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd";
use constant URI_CIMBIND 	=> 	"http://schemas.dmtf.org/wbem/wsman/1/cimbinding.xsd";
use constant URI_WSMID 	=> 	"http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd";

###Globale Action Namespaces###  
use constant  URI_ENUM 	=> 	"http://schemas.xmlsoap.org/ws/2004/09/enumeration"; 
use constant  URI_GET 	=> 	"http://schemas.xmlsoap.org/ws/2004/09/transfer/Get"; 
use constant  URI_PUT 	=> 	"http://schemas.xmlsoap.org/ws/2004/09/transfer/Put";
use constant  URI_FAULT 	=> 	"http://schemas.xmlsoap.org/ws/2004/08/addressing/fault";

###OEM Resource URI´s###
use constant  URI_DCIM 	=> 	"http://schemas.dell.com/wbem/wscim/1/cim-schema/2/";
use constant  URI_CIM 	=> 	"http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/";
use constant  URI_WMI  	=> 	"http://schemas.microsoft.com/wbem/wsman/1/wmi";
use constant  URI_WMICIMV2  => 	"http://schema.omc-project.org/wbem/wscim/1/cim-schema/2/";
use constant  URI_CIMV2  	=> 	"http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2";
use constant  URI_WINRM  	=> 	"http://schemas.microsoft.com/wbem/wsman/1";
use constant  URI_WSMAN  	=> 	"http://schemas.microsoft.com/wbem/wsman/1";
use constant  URI_SHELL  	=> 	"http://schemas.microsoft.com/wbem/wsman/1/windows/shell";
use constant  URI_WIN32     => 	"http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/";
use constant  URI_VMware 	=> 	"http://schemas.vmware.com/wbem/wscim/1/cim-schema/2/";

###Static Dialect URI´s###


use constant  ASSOCFI 	=> 	"http://schemas.dmtf.org/wbem/wsman/1/cimbinding/associationFilter";
use constant  FILTER  	=> 	"http://schemas.dmtf.org/wbem/cql/1/dsp0202.pdf";

1;

__END__
