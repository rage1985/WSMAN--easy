package WSMAN::easy;


=pod

## Version:          1.02  ##

Copyright 2013 Sascha Schaal

This file is part of WSMAN::easy.

WSMAN::easy is free software: you can redistribute it and/or modify it 
under the terms of the GNU General Public License as published 
by the Free Software Foundation, either version 3 of the License, 
or (at your option) any later version.

Foobar is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with WSMAN::easy.
If not, see http://www.gnu.org/licenses/.

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

# TODO: Bessere Methode zum einbinden der Konstanten finden.

use strict;
use warnings;

use Data::UUID;
use WWW::Curl::Easy; # Wir benutzen libCurl wegen des Leistungsgewinns gegeüber LWP
use MIME::Base64;
use Exporter;
use Data::Dumper; # Kann nach dem Debugging raus
use Carp;
use XML::LibXML;
use XML::Simple; # Eventuell bekomme ich es mit dem LibXML serializer hin dann kann das hier auch raus
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.02;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(new identify enumerate get invoke);


### Methoden einbinden###
my $xml = new XML::Simple;
my $ug   = new Data::UUID;

###Globale XML Namespaces###
my %Namespaces = (
    "SOAP" => "http://www.w3.org/2003/05/soap-envelope", 
    "ADDR" =>"http://schemas.xmlsoap.org/ws/2004/08/addressing", 
    "WSMAN" => "http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd",
    "CIMBIND" => "http://schemas.dmtf.org/wbem/wsman/1/cimbinding.xsd",
    "WSMID" => "http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd");

###Globale Action Namespaces###  
my %Actions = ( 
  "ENUM" => "http://schemas.xmlsoap.org/ws/2004/09/enumeration", 
  "GET" => "http://schemas.xmlsoap.org/ws/2004/09/transfer/Get", 
  "PUT" => "http://schemas.xmlsoap.org/ws/2004/09/transfer/Put",
  "FAULT" => "http://schemas.xmlsoap.org/ws/2004/08/addressing/fault");

###OEM Resource URI´s###
my %RURIs = (
  "DCIM" 	=> "http://schemas.dell.com/wbem/wscim/1/cim-schema/2/",
  "CIM"  	=> "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/",
  "WMI"  	=> "http://schemas.microsoft.com/wbem/wsman/1/wmi",
  "WMICIMV2"  	=> "http://schema.omc-project.org/wbem/wscim/1/cim-schema/2/",
  "CIMV2"  	=> "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2",
  "WINRM"  	=> "http://schemas.microsoft.com/wbem/wsman/1",
  "WSMAN"  	=> "http://schemas.microsoft.com/wbem/wsman/1",
  "SHELL"  	=> "http://schemas.microsoft.com/wbem/wsman/1/windows/shell",
  "WIN32"       => "http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/",
  "VMware" 	=> "http://schemas.vmware.com/wbem/wscim/1/cim-schema/2/");

###Static Dialect URI´s###

my %Dialect = (
  "ASSOCFI" => "http://schemas.dmtf.org/wbem/wsman/1/cimbinding/associationFilter",
  "FILTER"  => "http://schemas.dmtf.org/wbem/cql/1/dsp0202.pdf");

###XML erzeugen###
my $request = XML::LibXML::Document->new('1.0','UTF-8');

###Statischer Envelope###

my $envelope = $request->createElement("Envelope");
$envelope->setNamespace($Namespaces{"SOAP"} ,"s",1);
$envelope->setNamespace($Namespaces{"ADDR"}, "wsa", 0);
$envelope->setNamespace($Namespaces{"WSMAN"},"wsman",0);

###Statischer Header###

my $header = $request->createElement("Header");
$header->setNamespace($Namespaces{"SOAP"} ,"s",1);
$envelope->appendChild($header);



my $action = $request->createElement("Action");
my $to = $request->createElement("To");
my $ResourceURI = $request->createElement("ResourceURI");
my $MessageID = $request->createElement("MessageID");
my $ReplyTo = $request->createElement("ReplyTo");
my $selectorset; ### Muss hier deklariert werden damit sub close auf die Node-Referenz zugreifen kann 
$header->appendChild($action);
$header->appendChild($to);
$header->appendChild($ResourceURI);
$header->appendChild($MessageID);
$header->appendChild($ReplyTo);

###Statischer Body###

my $body = $request->createElement("Body");
$body->setNamespace($Namespaces{"SOAP"} ,"s",1);
$envelope->appendChild($body);

###Statische Aktion###

$action->setAttributeNS($Namespaces{"SOAP"},"mustUnderstand", "true");
$action->setNamespace($Namespaces{"ADDR"}, "wsa", 1);

###Statisches TO###

$to->setAttributeNS($Namespaces{"SOAP"},"mustUnderstand", "true");
$to->setNamespace($Namespaces{"ADDR"}, "wsa", 1);

###Statisches zur MessageID###

$MessageID->setAttributeNS($Namespaces{"SOAP"},"mustUnderstand", "true");
$MessageID->setNamespace($Namespaces{"ADDR"}, "wsa", 1);

###Statisches ReplayTo Feld###

$ReplyTo->setNamespace($Namespaces{"ADDR"}, "wsa", 1);
my $address = $request->createElement("Address");
$ReplyTo->appendChild($address);
$address->setNamespace($Namespaces{"ADDR"}, "wsa", 1);
$address->appendTextNode('http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous');

###Konstruktor WSMAN###
sub new {
  my $class = shift; 
  my %args  = @_;
 
  if ( !$args{"host"} || !$args{"port"} || !$args{"user"} || !$args{"passwd"} || !$args{"urlpath"}){
    croak "Parameter fehlt!"
  }

  my $self = bless {
    host	=>	$args{"host"},
    port	=>	$args{"port"},
    user	=>	$args{"user"},
    passwd	=>	$args{"passwd"},
    urlpath	=>	$args{"urlpath"},
    proto	=>	$args{"proto"},
    verbose	=>	$args{"verbose"}
  }, $class;
# TODO: Werte mit defaults initialisieren.
  return $self;
}

###WSMAN Identify###

sub identify{
  
  my $self = shift;

  my $identify = XML::LibXML::Document->new('1.0');
  my $ident_envelope = $request->createElement("Envelope");
  $ident_envelope->setNamespace($Namespaces{"SOAP"} ,"s",1);
  $ident_envelope->setNamespace($Namespaces{"WSMID"}, "wsmid",0);

  my $ident_header = $request->createElement("Header");
  $ident_header->setNamespace($Namespaces{"SOAP"} ,"s",1);
  $ident_envelope->appendChild($ident_header);
  $ident_envelope->appendChild($body);

  my $ident = $identify->createElement("Identify");
  $ident->setNamespace($Namespaces{"WSMID"}, "wsmid",1);
  $body->appendChild($ident);
  
  $identify->setDocumentElement($ident_envelope);

  #print $identify->toString(2);
  
  $self->_CONNECT($identify->toString(2));

}

###WSAMAN Enumeration###
sub enumerate{
  
  my $self = shift;
  my %args = @_;
  my $ug   = new Data::UUID;
  my $UUID = $ug->create_str(); ###Neue UUID für jeden Vorgang
  
  if ( !$args{"class"}){
    croak "Class fehlt!"
  }
# TODO: Werte mit defaults initialisieren. 
  $envelope->setNamespace($Actions{"ENUM"},"wsen",0);
  $action->appendTextNode("$Actions{'ENUM'}/Enumerate");
  $to->appendTextNode("$self->{'proto'}://$self->{'host'}:$self->{'port'}/$self->{'urlpath'}");
  $MessageID->appendTextNode("uuid:$UUID");


  $self->_SETRURI($args{"class"});

  my $enumeration = $request->createElement("Enumerate");
  $enumeration->setNamespace($Actions{"ENUM"},"wsen",1);
  $body->appendChild($enumeration);

  if (exists $args{"ns"}){
    $self->_SELECTORSET({__cimnamepace => $args{"ns"}});
  }

  if ( exists $args{"optimized"}){
    my $optimize_enum = $request->createElement("OptimizeEnumeration");
    $optimize_enum->setNamespace($Namespaces{"WSMAN"},"wsman",1);
    $enumeration->appendChild($optimize_enum);
  }
  if ( exists $args{"maxelements"}){
    my $max_elements = $request->createElement("MaxElements");
    $max_elements->setNamespace($Namespaces{"WSMAN"},"wsman",1);
    $max_elements->appendTextNode($args{"maxelements"});
    $enumeration->appendChild($max_elements);
  }
  
  if ( exists $args{"eprmode"}){
    my $epr_mode = $request->createElement("EnumerationMode");
    $epr_mode->setNamespace($Namespaces{"WSMAN"},"wsman",1);
    $epr_mode->appendTextNode("EnumerateEPR");
    $enumeration->appendChild($epr_mode);
  }
  
  if (exists $args{"SelectorSet"}){
    $self->_SELECTORSET($args{"SelectorSet"});
  }
  
  if (exists $args{"Filter"}){
    my $Filter = $request->createElement("Filter");
    $Filter->setNamespace($Namespaces{"WSMAN"},"wsman",1);
    $Filter->setAttribute("Dialect", $Dialect{"FILTER"});
    $Filter->appendTextNode($args{"Filter"});
    $enumeration->appendChild($Filter);  
  }
  $request->setDocumentElement($envelope);
  
  #print $request->toString(2);

  return $self->_CONNECT($request->toString(2));
}

sub get{

  my $self = shift;
  my %args = @_;
  my $ug   = new Data::UUID;
  my $UUID = $ug->create_str(); ###Neue UUID für jeden Vorgang
  
  if ( !$args{"class"}){
    croak "Class fehlt!"
  }
# TODO: Werte mit defaults initialisieren.

  $envelope->setNamespace($Actions{"ENUM"},"wsen",0);
  $action->appendTextNode($Actions{"GET"});
  $to->appendTextNode("$self->{'proto'}://$self->{'host'}:$self->{'port'}/$self->{'urlpath'}");
  $MessageID->appendTextNode("uuid:$UUID");

  $self->_SETRURI($args{"class"});
  $self->_SELECTORSET($args{"SelectorSet"});

  $request->setDocumentElement($envelope);

  #print $request->toString(2);
  
  return $self->_CONNECT($request->toString(2));
}

sub invoke{

  my $self = shift;
  my $args = @_;
  my $ug   = new Data::UUID;
  my $UUID = $ug->create_str(); ###Neue UUID für jeden Vorgang

  if ( !$args->{"class"}){
    croak "Klasse fehlt!"
  }
# TODO: Werte mit defaults initialisieren.
  $self->_SETRURI($args->{"class"});  

  $envelope->setNamespace($Actions{"ENUM"},"wsen",0);
  $action->appendTextNode("$RURIs{'DCIM'}/$args->{'InvokeClass'}");
  $to->appendTextNode("$self->{'proto'}://$self->{'host'}:$self->{'port'}/$self->{'urlpath'}");
  $MessageID->appendTextNode("uuid:$UUID");

  $self->_SELECTORSET($args->{"SelectorSet"});

  my $invoke = $request->createElement("$args->{'InvokeClass'}_INPUT");
  $invoke->setNamespace("$RURIs{'DCIM'}", "p", 1);
  $body->appendChild($invoke);
  
  my %Invoke_Input = $args->{"Invoke_Input"};
  while ( my ($k,$v) = each %Invoke_Input ) {
    my $invoke_input = $request->createElement("$k");
    $invoke_input->setNamespace("$RURIs{'DCIM'}", "p", 1);
    $invoke_input->appendTextNode($v);
    $invoke->appendChild($invoke_input);
    }
  
  if (exists $args->{"Filter"}){
    my $Filter = $request->createElement("Filter");
    $Filter->setNamespace($Namespaces{"WSMAN"},"wsman",1);
    $Filter->setAttribute("Dialect", $Dialect{"FILTER"});
    $Filter->appendTextNode($args->{"Filter"});
    $body->appendChild($Filter);  
  }

  $request->setDocumentElement($envelope);
  
  #print $request->toString(2);

  return $self->_CONNECT($request->toString(2));
}

###Private Methode für Selektoren###

sub _SELECTORSET{

  my $self = shift;
  my $args = $_[0];
  	
  $selectorset = $request->createElement("SelectorSet");
  $selectorset->setNamespace($Namespaces{"WSMAN"},"wsman",1);
  while ( my ($k,$v) = each %$args ) {
    my $selector = $request->createElement("Selector");
    $selector->setAttribute('Name', $k);
    $selector->setNamespace($Namespaces{"WSMAN"},"wsman",1);
    $selector->appendTextNode($v);
    $selectorset->appendChild($selector);
  }
  $header->appendChild($selectorset);

   
}
# TODO: Abgewandelte Methode für das setzen von Namespaces erstellen, dabei Racing-Condition vermeiden.

###Private Methode für Klassen URI´s###

sub _SETRURI{

  my $self = shift;
  my @args = @_;
  

  my @RURIP = split /_/, $args[0]; # Komfortfunktion: Bildet RURI aus der Endpoint Reference.
  $ResourceURI->setAttributeNS($Namespaces{"SOAP"},"mustUnderstand", "true");
  $ResourceURI->setNamespace($Namespaces{"WSMAN"},"wsman",1);
  $ResourceURI->removeChildNodes();	
  if ($RURIP[0] eq "CIM"){
    $ResourceURI->appendTextNode("$RURIs{'CIM'}$args[0]");
    }
    elsif ($RURIP[0] eq "DCIM"){
      $ResourceURI->appendTextNode("$RURIs{'DCIM'}$args[0]");
    }
    elsif ($RURIP[0] eq "OMC"){
      $ResourceURI->appendTextNode("$RURIs{'OMC'}$args[0]");
    }
    elsif ($RURIP[0] eq "VMware"){
      $ResourceURI->appendTextNode("$RURIs{'VMware'}$args[0]");
    }
    elsif ($RURIP[0] eq "WIN32"){
      $ResourceURI->appendTextNode("$RURIs{'WIN32'}$args[0]");
    }
    elsif ($RURIP[0] eq "WMI"){
      $ResourceURI->appendTextNode("$RURIs{'WMI'}$args[0]");
    }
    elsif ($RURIP[0] eq "WMICIMV2"){
      $ResourceURI->appendTextNode("$RURIs{'WMICIMV2'}$args[0]");
    }
    elsif ($RURIP[0] eq "CIMV2"){
      $ResourceURI->appendTextNode("$RURIs{'CIMV2'}$args[0]");
    }
    elsif ($RURIP[0] eq "WINRM"){
      $ResourceURI->appendTextNode("$RURIs{'WINRM'}$args[0]");
    }
    elsif ($RURIP[0] eq "WSMAN"){
      $ResourceURI->appendTextNode("$RURIs{'WSMAN'}$args[0]");
    }
    elsif ($RURIP[0] eq "SHELL"){
      $ResourceURI->appendTextNode("$RURIs{'SHELL'}$args[0]");
    }
    else{
      croak "Fehler bei Klasse"}

    $args[0] = "";

}


###Private Connection Method###
sub _CONNECT{

  my $self = shift;

  my $curl = WWW::Curl::Easy->new;
  $curl->setopt( CURLOPT_VERBOSE, "$self->{'verbose'}");
  $curl->setopt( CURLOPT_SSL_VERIFYHOST, 0);
  $curl->setopt( CURLOPT_SSL_VERIFYPEER, 0);
  $curl->setopt( CURLOPT_URL,            "$self->{'proto'}://$self->{'host'}/$self->{'urlpath'}");
  $curl->setopt( CURLOPT_USERPWD,        "$self->{'user'}:$self->{'passwd'}");
  $curl->setopt( CURLOPT_FOLLOWLOCATION, 1);
  
  $curl->setopt( CURLOPT_PORT,		,$self->{"port"});
  $curl->setopt( CURLOPT_HEADER(),	0		);
  $curl->setopt( CURLOPT_HTTPHEADER(), ['Content-Type: application/soap+xml;charset=UTF-8']);

  my $response_body;
  $curl->setopt( CURLOPT_POST,       1 );
  $curl->setopt( CURLOPT_TIMEOUT,    120 );
  $curl->setopt( CURLOPT_POSTFIELDS, $_[0] );
  $curl->setopt( CURLOPT_WRITEDATA,  \$response_body );

  my $retcode = $curl->perform;

  if ( $retcode == 0 ) {
    
    #print $response_body;


    my $data = $xml->XMLin($response_body); # TODO: Serializer von XML::LibXML nutzen. Dann kann XML::Simple raus.
 
    if (exists $data->{'s:Header'}->{'wsa:Action'}){
      if ($data->{'s:Header'}->{'wsa:Action'} eq 'http://schemas.dmtf.org/wbem/wsman/1/wsman/fault' || $data->{'s:Header'}->{'wsa:Action'} eq 'http://schemas.xmlsoap.org/ws/2004/08/addressing/fault'){
        croak "WSMAN FAULT: ", $data->{'s:Body'}->{'s:Fault'}->{'s:Reason'}->{'s:Text'}->{'content'}; # TODO: exeption handling prüfen -> werden alle WSMan errors abgefangen ?
      }

        else{
          return $data;
        }
    }
    else{
      return $data;
    }
  }
  else {

    # HTTP Error code, type of error, error message
    croak ("Code:$retcode " . $curl->strerror($retcode) . " " . $curl->errbuf . "\n") ;

  }
}

sub close{

 my $self = shift;
  
 $action->removeChildNodes();
 $to->removeChildNodes();
 $MessageID->removeChildNodes();
 $body->removeChildNodes();
 $header->removeChild($selectorset);
# TODO: destroyer einbinden.
}

1; # Module müssen einen Rückgabewert von 1 haben.
