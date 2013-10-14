package WSMAN::Simple;


=pod

## Version:          1.02  ##

Copyright 2013 Sascha Schaal

This file is part of WSMAN::easy.

WSMAN::easy is free software: you can redistribute it and/or modify it 
under the terms of the GNU General Public License as published 
by the Free Software Foundation, either version 3 of the License, 
or (at your option) any later version.

WSMAN::easy is distributed in the hope that it will be useful,
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



use strict;
use warnings;

use Data::UUID;
use Data::Dumper; 
use Carp;
use XML::LibXML;
use XML::Simple; 	
use LWP::UserAgent;

use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.02;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(session identify enumerate get invoke URI_SOAP URI_ADDR URI_WSMAN1 URI_CIMBIND URI_WSMID URI_ENUM URI_GET URI_PUT URI_FAULT URI_DCIM URI_CIM URI_WMI URI_WMICIMV2
URI_CIMV2 URI_WINRM URI_WSMAN URI_SHELL URI_WIN32 URI_VMware URI_ASSOCFI URI_FILTER );

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


###Konstruktor WSMAN###
sub session {
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
    verbose	=>	$args{"verbose"},
    REQUEST => { 
                          DOC => "",
                          ENVELOPE => "",
                          HEADER => "",
                          TO => "",
                          RURI => "",
                          MID => "",
                          RPLTO => "",
                          BODY => "",
                          ADDR => ""
                          }
  }, $class;
# TODO: Werte mit defaults initialisieren.
print Dumper($self);
_BUILD_MESSAGE($self);
print Dumper($self);

  return $self;
}

###WSMAN Identify###
=pod
sub identify{
  
  my $self = shift;

  my $identify = XML::LibXML::Document->new('1.0');
  my $ident_envelope = $request->createElement("Envelope");
  $ident_envelope->setNamespace(URI_SOAP ,"s",1);
  $ident_envelope->setNamespace(URI_WSMID, "wsmid",0);

  my $ident_header = $request->createElement("Header");
  $ident_header->setNamespace(URI_SOAP ,"s",1);
  $ident_envelope->appendChild($ident_header);
  $ident_envelope->appendChild($body);

  my $ident = $identify->createElement("Identify");
  $ident->setNamespace(URI_WSMID, "wsmid",1);
  $body->appendChild($ident);
  
  $identify->setDocumentElement($ident_envelope);

  print $identify->toString(2);
  
  #$self->_CONNECT($identify->toString(2));
  #$self->_CONNECT2($identify->toString(2));

}
=cut

###WSAMAN Enumeration###
=pod
sub enumerate{
  
  my $self = shift;
  my %args = @_;
  my $ug   = new Data::UUID;
  my $UUID = $ug->create_str(); ###Neue UUID für jeden Vorgang
  
  if ( !$args{"class"}){
    croak "Class fehlt!"
  }
# TODO: Werte mit defaults initialisieren. 
  $envelope->setNamespace(URI_ENUM,"wsen",0);
  $action->appendTextNode("@{[URI_ENUM]}/Enumerate");
  $to->appendTextNode("$self->{'proto'}://$self->{'host'}:$self->{'port'}/$self->{'urlpath'}");
  $MessageID->appendTextNode("uuid:$UUID");


  $self->_SETRURI($args{"class"});

  my $enumeration = $request->createElement("Enumerate");
  $enumeration->setNamespace(URI_ENUM,"wsen",1);
  $body->appendChild($enumeration);

  if (exists $args{"ns"}){
    $self->_SELECTORSET({__cimnamepace => $args{"ns"}});
  }

  if ( exists $args{"optimized"}){
    my $optimize_enum = $request->createElement("OptimizeEnumeration");
    $optimize_enum->setNamespace(URI_WSMAN1,"wsman",1);
    $enumeration->appendChild($optimize_enum);
  }
  if ( exists $args{"maxelements"}){
    my $max_elements = $request->createElement("MaxElements");
    $max_elements->setNamespace(URI_WSMAN1,"wsman",1);
    $max_elements->appendTextNode($args{"maxelements"});
    $enumeration->appendChild($max_elements);
  }
  
  if ( exists $args{"eprmode"}){
    my $epr_mode = $request->createElement("EnumerationMode");
    $epr_mode->setNamespace(URI_WSMAN1,"wsman",1);
    $epr_mode->appendTextNode("EnumerateEPR");
    $enumeration->appendChild($epr_mode);
  }
  
  if (exists $args{"SelectorSet"}){
    $self->WSMAN::Simple::Generic::_SELECTORSET($args{"SelectorSet"});
  }
  
  if (exists $args{"Filter"}){
    my $Filter = $request->createElement("Filter");
    $Filter->setNamespace(URI_WSMAN1,"wsman",1);
    $Filter->setAttribute("Dialect", URI_FILTER);
    $Filter->appendTextNode($args{"Filter"});
    $enumeration->appendChild($Filter);  
  }
  $request->setDocumentElement($envelope);
  
  print $request->toString(2);

  #return $self->_CONNECT($request->toString(2));
}
=cut

###WSMAN GET###
=pod
sub get{

  my $self = shift;
  my %args = @_;
  my $ug   = new Data::UUID;
  my $UUID = $ug->create_str(); ###Neue UUID für jeden Vorgang
  
  if ( !$args{"class"}){
    croak "Class fehlt!"
  }
# TODO: Werte mit defaults initialisieren.

  $envelope->setNamespace(URI_ENUM,"wsen",0);
  $action->appendTextNode(URI_GET);
  $to->appendTextNode("$self->{'proto'}://$self->{'host'}:$self->{'port'}/$self->{'urlpath'}");
  $MessageID->appendTextNode("uuid:$UUID");

  $self->WSMAN::Simple::Generic::_SETRURI($args{"class"});
  $self->WSMAN::Simple::Generic::_SELECTORSET($args{"SelectorSet"});

  $request->setDocumentElement($envelope);

  print $request->toString(2);
  
  #return $self->_CONNECT($request->toString(2));
}
=cut
###WSMAN Invoke###
=pod
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

  $envelope->setNamespace(URI_ENUM,"wsen",0);
  $action->appendTextNode("@{['DCIM']}$args->{'InvokeClass'}");
  $to->appendTextNode("$self->{'proto'}://$self->{'host'}:$self->{'port'}/$self->{'urlpath'}");
  $MessageID->appendTextNode("uuid:$UUID");

  $self->_SELECTORSET($args->{"SelectorSet"});

  my $invoke = $request->createElement("$args->{'InvokeClass'}_INPUT");
  $invoke->setNamespace(URI_DCIM, "p", 1);
  $body->appendChild($invoke);
  
  my %Invoke_Input = $args->{"Invoke_Input"};
  while ( my ($k,$v) = each %Invoke_Input ) {
    my $invoke_input = $request->createElement("$k");
    $invoke_input->setNamespace(URI_DCIM, "p", 1);
    $invoke_input->appendTextNode($v);
    $invoke->appendChild($invoke_input);
    }
  
  if (exists $args->{"Filter"}){
    my $Filter = $request->createElement("Filter");
    $Filter->setNamespace(URI_WSMAN1,"wsman",1);
    $Filter->setAttribute("Dialect", URI_FILTER);
    $Filter->appendTextNode($args->{"Filter"});
    $body->appendChild($Filter);  
  }

  $request->setDocumentElement($envelope);
  
  print $request->toString(2);

  #return $self->_CONNECT($request->toString(2));
}
=cut



sub _BUILD_MESSAGE{
  
my ($self) = @_;
print Dumper(@_);
$self->{'REQUEST'}->{'DOC'} = XML::LibXML::Document->new('1.0','UTF-8');

###Statischer Envelope###

$self->{'REQUEST'}->{'ENVELOPE'} = $self->{'REQUEST'}->{'DOC'}->createElement("Envelope");
$self->{'REQUEST'}->{'ENVELOPE'} ->setNamespace(URI_SOAP ,"s",1);
$self->{'REQUEST'}->{'ENVELOPE'}->setNamespace(URI_ADDR, "wsa", 0);
$self->{'REQUEST'}->{'ENVELOPE'}->setNamespace(URI_WSMAN1,"wsman",0);

###Statischer Header###

$self->{'REQUEST'}->{'HEADER'} = $self->{'REQUEST'}->{'DOC'}->createElement("Header");
$self->{'REQUEST'}->{'HEADER'}->setNamespace(URI_SOAP ,"s",1);
$self->{'REQUEST'}->{'ENVELOPE'}->appendChild($self->{'REQUEST'}->{'HEADER'});

$self->{'REQUEST'}->{'ACTION'} = $self->{'REQUEST'}->{'DOC'}->createElement("Action");
$self->{'REQUEST'}->{'TO'} = $self->{'REQUEST'}->{'DOC'}->createElement("To");
$self->{'REQUEST'}->{'RURI'}= $self->{'REQUEST'}->{'DOC'}->createElement("ResourceURI");
$self->{'REQUEST'}->{'MID'} = $self->{'REQUEST'}->{'DOC'}->createElement("MessageID");
$self->{'REQUEST'}->{'RPLTO'}  = $self->{'REQUEST'}->{'DOC'}->createElement("ReplyTo");

$self->{'REQUEST'}->{'HEADER'}->appendChild($self->{'REQUEST'}->{'ACTION'});
$self->{'REQUEST'}->{'HEADER'}->appendChild($self->{'REQUEST'}->{'TO'});
$self->{'REQUEST'}->{'HEADER'}->appendChild($self->{'REQUEST'}->{'RURI'});
$self->{'REQUEST'}->{'HEADER'}->appendChild($self->{'REQUEST'}->{'MID'});
$self->{'REQUEST'}->{'HEADER'}->appendChild($self->{'REQUEST'}->{'RPLTO'});

###Statischer Body###

$self->{'REQUEST'}->{'BODY'}= $self->{'REQUEST'}->{'DOC'}->createElement("Body");
$self->{'REQUEST'}->{'BODY'}->setNamespace(URI_SOAP ,"s",1);
$self->{'REQUEST'}->{'ENVELOPE'}->appendChild($self->{'REQUEST'}->{'BODY'});

###Statische Aktion###

$self->{'REQUEST'}->{'ACTION'}->setAttributeNS(URI_SOAP,"mustUnderstand", "true");
$self->{'REQUEST'}->{'ACTION'}->setNamespace(URI_ADDR, "wsa", 1);

###Statisches TO###

$self->{'REQUEST'}->{'TO'}->setAttributeNS(URI_SOAP,"mustUnderstand", "true");
$self->{'REQUEST'}->{'TO'}->setNamespace(URI_ADDR, "wsa", 1);

###Statisches zur MessageID###

$self->{'REQUEST'}->{'MID'}->setAttributeNS(URI_SOAP,"mustUnderstand", "true");
$self->{'REQUEST'}->{'MID'}->setNamespace(URI_ADDR, "wsa", 1);

###Statisches ReplayTo Feld###

$self->{'REQUEST'}->{'RPLTO'}->setNamespace(URI_ADDR, "wsa", 1);
$self->{'REQUEST'}->{'ADDR'} = $self->{'REQUEST'}->{'DOC'}->createElement("Address");
$self->{'REQUEST'}->{'RPLTO'}->appendChild($self->{'REQUEST'}->{'ADDR'});
$self->{'REQUEST'}->{'ADDR'}->setNamespace(URI_ADDR, "wsa", 1);
$self->{'REQUEST'}->{'ADDR'}->appendTextNode('http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous');

print Dumper($self);

print $self->{'REQUEST'}->{'DOC'}->toString() unless $self->{'verbose'} == 0;
}

###privat Method for Selector-Sets###
sub _SELECTORSET{

  my $self = shift;
  my $args = $_[0];
  	
  $self->{'REQUEST'}->{'SELSET'} = $self->{'EXMLOBJ'}->createElement("SelectorSet");
  $self->{'REQUEST'}->{'SELSET'}->setNamespace(URI_WSMAN1,"wsman",1);
  while ( my ($k,$v) = each %$args ) {
    my $selector = $self->{'REQUEST'}->{'EXMLOBJ'}->createElement("Selector");
    $selector->setAttribute('Name', $k);
    $selector->setNamespace(URI_WSMAN1,"wsman",1);
    $selector->appendTextNode($v);
    $self->{'REQUEST'}->{'SELSET'}->appendChild($selector);
  }
  $self->{'REQUEST'}->{'HEADER'}->appendChild($self->{'REQUEST'}->{'SELSET'});

   
}

# TODO: Abgewandelte Methode für das setzen von Namespaces erstellen, dabei Racing-Condition vermeiden.

###privat Method for Class URI generation###

sub _SETRURI{

  my $self = shift;
  my @args = @_;

  my $ResourceURI = $self->{'REQUEST'}->{'RURI'};  

  my @RURIP = split /_/, $args[0]; # Komfortfunktion: Bildet RURI aus der Endpoint Reference.
  $ResourceURI->setAttributeNS(URI_SOAP,"mustUnderstand", "true");
  $ResourceURI->setNamespace(URI_WSMAN1,"wsman",1);
  $ResourceURI->removeChildNodes();	
  if ($RURIP[0] eq "CIM"){
    $ResourceURI->appendTextNode("@{[URI_CIM]}$args[0]");
  } elsif ($RURIP[0] eq "DCIM"){
      $ResourceURI->appendTextNode("@{[URI_DCIM]}$args[0]");
  } elsif ($RURIP[0] eq "OMC"){
      $ResourceURI->appendTextNode("@{[&URI_OMC]}$args[0]");
  } elsif ($RURIP[0] eq "VMware"){
      $ResourceURI->appendTextNode("@{[URI_VMware]}$args[0]");
 } elsif ($RURIP[0] eq "WIN32"){
      $ResourceURI->appendTextNode("@{[URI_WIN32]}$args[0]");
 } elsif ($RURIP[0] eq "WMI"){
      $ResourceURI->appendTextNode("@{[URI_WMI]}$args[0]");
 } elsif ($RURIP[0] eq "WMICIMV2"){
      $ResourceURI->appendTextNode("@{[URI_WMICIMV2]}$args[0]");
 } elsif ($RURIP[0] eq "CIMV2"){
      $ResourceURI->appendTextNode("@{[URI_CIMV2]}$args[0]");
 } elsif ($RURIP[0] eq "WINRM"){
      $ResourceURI->appendTextNode("@{[URI_WINRM]}$args[0]");
 } elsif ($RURIP[0] eq "WSMAN"){
      $ResourceURI->appendTextNode("@{[URI_WSMAN1]}$args[0]");
 } elsif ($RURIP[0] eq "SHELL"){
      $ResourceURI->appendTextNode("@{[URI_SHELL]}$args[0]");
 } else{
      croak "Fehler bei Klasse"}

    $args[0] = "";

}


###Private Connection Method###
=pod
 sub _CONNECT_OLD{

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
    
    print $response_body;


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
=cut
sub _CONNECT{

  my $self = shift;

  my $ua = new LWP::UserAgent;
  $ua->credentials("$self->{'host'}/$self->{'urlpath'}", "$self->{'urlpath'}" );
  #$ua->ssl_opts( verify_hostname => 0, verify_peer => 0 );

  my $req = new HTTP::Request 'POST',"$self->{'proto'}://$self->{'host'}:$self->{'port'}/$self->{'urlpath'}";
  #print $req;
  $req->content_type('application/soap+xml;charset=UTF-8');
  $req->authorization_basic($self->{'user'}, $self->{'passwd'});
  $req->content($_[0]);

  my $res = $ua->request($req);
  #print $res->as_string;
  my $result = $res->content();
  print $result;
  
  return $result;

}

sub _PARSER{
  
  my $self = shift;
  my $args = @_;
  print $_[0];
  
  
  
  
  my $parser = XML::LibXML->new();

my $doc = XML::LibXML->load_xml(
      string => $_[0]
      # parser options ...
    );

my $root = $doc->documentElement();

my @nodes = $root->findnodes( './s:Body/n:PullResponse/n:Items/*') && $root->findnodes('./s:Body/wsmid:IdentifyResponse/*');
my $output;
my @childnodes;
my @childnodes2;
my @childnodes3;

foreach (@nodes){
  $output .= "----";
  $output .= $_->localName;
  $output .= "----\n";
  if ($_->hasChildNodes() == '1'){
    @childnodes = $_->childNodes();
    foreach (@childnodes){
      if ($_->nodeName ne '#text' && $_->hasChildNodes() == '1'){
        $output .= $_->localName;
        $output .= " -> ";
        @childnodes2 = $_->childNodes();
          foreach (@childnodes2){
            if ($_->hasChildNodes() == '0'){
              $output .= $_->nodeValue;
              $output .= "\n";
            }
        else{
          @childnodes3 = $_->childNodes();
          foreach (@childnodes3){
            if ($_->hasChildNodes() == '0'){
              $output .= $_->nodeValue;
              $output .= "\n";
            }
          }
        
      }
    }
  }
}   
  }
  else{
  print $_->localName," hat keine childnodes\n";
  }
  
};

return $output;
}

sub close{

 my $self = shift;
  
 $self->{'REQUEST'}->{'ACTION'}->removeChildNodes();
 $self->{'REQUEST'}->{'TO'}->removeChildNodes();
 $self->{'REQUEST'}->{'MID'}->removeChildNodes();
 $self->{'REQUEST'}->{'BODY'}->removeChildNodes();
 $self->{'REQUEST'}->{'HEADER'}->removeChild($self->{'REQUEST'}->{'SELSET'});

}

1; # Module müssen einen Rückgabewert von 1 haben.
