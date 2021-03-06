package lib::easy;


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
no warnings 'once';
use Data::UUID;
use Exporter;
use Carp;
use XML::LibXML;
use LWP::UserAgent;
use Net::SSL ();

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);


$VERSION     = 1.02;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(session identify enumerate get invoke URI_SOAP URI_ADDR URI_WSMAN1 URI_CIMBIND URI_WSMID URI_ENUM URI_GET URI_PUT URI_FAULT URI_DCIM URI_CIM URI_WMI URI_WMICIMV2
URI_CIMV2 URI_WINRM URI_WSMAN URI_SHELL URI_WIN32 URI_VMWAREURI_ASSOCFI URI_FILTER );

%EXPORT_TAGS = (
		namespaces => [qw(
					@{[URI_SOAP]}
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
					URI_VMWARE
					URI_OMC
				)],
		dialect => [qw(
					URI_ASSOCFI
					URI_FILTER
				)]
		);


BEGIN {
 $Net::HTTPS::SSL_SOCKET_CLASS = "Net::SSL"; # Force use of Net::SSL
 $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
#$ENV{HTTPS_DEBUG} = 3;
#$ENV{PERL_LWP_SSL_VERIFY_PEER} = 0;
}

###Global XML Namespaces###
use constant URI_SOAP 		=>	"http://www.w3.org/2003/05/soap-envelope"; 
use constant URI_ADDR 		=>	"http://schemas.xmlsoap.org/ws/2004/08/addressing";
use constant URI_WSMAN1		=> 	"http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd";
use constant URI_CIMBIND 	=> 	"http://schemas.dmtf.org/wbem/wsman/1/cimbinding.xsd";
use constant URI_WSMID 		=> 	"http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd";

###Global Action Namespaces###  
use constant  URI_ENUM 		=> 	"http://schemas.xmlsoap.org/ws/2004/09/enumeration"; 
use constant  URI_GET 		=> 	"http://schemas.xmlsoap.org/ws/2004/09/transfer/Get"; 
use constant  URI_PUT 		=> 	"http://schemas.xmlsoap.org/ws/2004/09/transfer/Put";
use constant  URI_FAULT 	=> 	"http://schemas.xmlsoap.org/ws/2004/08/addressing/fault";

###OEM Resource URI´s###
use constant  URI_DCIM 		=> 	"http://schemas.dell.com/wbem/wscim/1/cim-schema/2/";
use constant  URI_CIM 		=> 	"http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/";
use constant  URI_WMI  		=> 	"http://schemas.microsoft.com/wbem/wsman/1/wmi";
use constant  URI_WMICIMV2  	=> 	"http://schema.omc-project.org/wbem/wscim/1/cim-schema/2/";
use constant  URI_CIMV2  	=> 	"http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2";
use constant  URI_WINRM  	=> 	"http://schemas.microsoft.com/wbem/wsman/1";
use constant  URI_WSMAN  	=> 	"http://schemas.microsoft.com/wbem/wsman/1";
use constant  URI_SHELL  	=> 	"http://schemas.microsoft.com/wbem/wsman/1/windows/shell";
use constant  URI_WIN32     	=> 	"http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/";
use constant  URI_VMWARE	=> 	"http://schemas.vmware.com/wbem/wscim/1/cim-schema/2/";
use constant URI_OMC 		=>	"http://schema.omc-project.org/wbem/wscim/1/cim-schema/2/";

###Static Dialect URI´s###

use constant  ASSOCFI 		=> 	"http://schemas.dmtf.org/wbem/wsman/1/cimbinding/associationFilter";
use constant  FILTER  		=> 	"http://schemas.dmtf.org/wbem/cql/1/dsp0202.pdf";

my $selectorset;

###HTTP/HTTPS SOAP Session Constructor###
sub session {
  my $class = shift; 
  my %args  = @_;
 
  if ( !$args{"host"} || !$args{"port"} || !$args{"user"} || !$args{"passwd"} || !$args{"urlpath"}){
    croak "parameter missing!  host, port, user, passwd and urlpath are mandatory"
  }
  my $doc = XML::LibXML::Document->new('1.0','UTF-8');
  my $self = bless {
    host	=>	$args{"host"},
    port	=>	$args{"port"},
    user	=>	$args{"user"},
    passwd	=>	$args{"passwd"},
    urlpath	=>	$args{"urlpath"},
    proto	=>	$args{"proto"},
    verbose	=>	$args{"verbose"},
    ssl_host	=>	$args{"ssl_verify_host"},
    timeout  =>   $args{"timeout"} ,
    _doc	=>	$doc
    
   
  }, $class;
# TODO: Werte mit defaults initialisieren.
  return $self;
}

###WSMAN Identify###
sub identify{
  
  my $self = shift;

  my $message = $self->_BUILD_MESSAGE();

  my $identify = XML::LibXML::Document->new('1.0');
  my $ident_envelope = $self->{'_doc'}->createElement("Envelope");
  $ident_envelope->setNamespace(@{[URI_SOAP]} ,"s",1);
  $ident_envelope->setNamespace(@{[URI_WSMID]}, "wsmid",0);

  my $ident_header = $self->{'_doc'}->createElement("Header");
  $ident_header->setNamespace(@{[URI_SOAP]} ,"s",1);
  $ident_envelope->appendChild($ident_header);
  $ident_envelope->appendChild($message->{'BODY'});

  my $ident = $identify->createElement("Identify");
  $ident->setNamespace(@{[URI_WSMID]}, "wsmid",1);
  $message->{'BODY'}->appendChild($ident);
  
  $identify->setDocumentElement($ident_envelope);
  
  my $request = $self->{'_doc'}->toString(2);

  if ($self->{'verbose'} == 1){
    print "GENERATED SOAP REQUEST: \n";
    print "-------------------------------------------------------------------------------------------------------\n"; 
    print $request;
    print "\n";
  }
  $self->_CONNECT($identify->toString(2));
  

}

###WSAMAN Enumeration###
sub enumerate{
  
  my $self = shift;
  my %args = @_;
  my $ug   = new Data::UUID;
  my $UUID = $ug->create_str(); ###Neue UUID für jeden Vorgang
 
  my $message = $self->_BUILD_MESSAGE();
  
  if ( !$args{"class"}){
    croak 'ENUMERATE ERROR no class submitted to enumerate method'
  }
   
  $message->{'ENV'}->setNamespace(@{[URI_ENUM]},"wsen",0);
  $message->{'ACTION'}->appendTextNode("@{[URI_ENUM]}/Enumerate");
  $message->{'TO'}->appendTextNode("$self->{'proto'}://$self->{'host'}:$self->{'port'}/$self->{'urlpath'}");
  $message->{'MID'}->appendTextNode("uuid:$UUID");

  my $ruri = $message->{'RURI'};
  my $ruritxt = $self->_SETRURI($args{"class"});
  $ruri->setAttributeNS(@{[URI_SOAP]},"mustUnderstand", "true");
  $ruri->setNamespace(@{[URI_WSMAN1]},"wsman",1);
  $ruri->removeChildNodes();
  $ruri->appendTextNode($ruritxt);

  my $enumeration = $self->{'_doc'}->createElement("Enumerate");
  $enumeration->setNamespace(@{[URI_ENUM]},"wsen",1);
  $message->{'BODY'}->appendChild($enumeration);

  if (exists $args{"ns"}){
    my $ns = $self->_SELECTORSET({__cimnamepace => $args{'ns'}});
    $message->{'HEAD'}->appendChild($ns);
  }

  if ( exists $args{"optimized"}){
    my $optimize_enum = $self->{'_doc'}->createElement("OptimizeEnumeration");
    $optimize_enum->setNamespace(@{[URI_WSMAN1]},"wsman",1);
    $enumeration->appendChild($optimize_enum);
  }
  if ( exists $args{"maxelements"}){
    my $max_elements = $self->{'_doc'}->createElement("MaxElements");
    $max_elements->setNamespace(@{[URI_WSMAN1]},"wsman",1);
    $max_elements->appendTextNode($args{"maxelements"});
    $enumeration->appendChild($max_elements);
  }
  
  if ( exists $args{"eprmode"}){
    my $epr_mode = $self->{'_doc'}->createElement("EnumerationMode");
    $epr_mode->setNamespace(@{[URI_WSMAN1]},"wsman",1);
    $epr_mode->appendTextNode("EnumerateEPR");
    $enumeration->appendChild($epr_mode);
  }
  
  if (exists $args{"SelectorSet"}){
    my $selset = $self->_SELECTORSET($args{"SelectorSet"});
    $message->{'HEAD'}->appendChild($selset);
  }
  
  if (exists $args{"Filter"}){
    my $Filter = $self->{'_doc'}->createElement("Filter");
    $Filter->setNamespace(@{[URI_WSMAN1]},"wsman",1);
    $Filter->setAttribute("Dialect", @{[FILTER]});
    $Filter->appendTextNode($args{"Filter"});
    $enumeration->appendChild($Filter);  
  }
  $self->{'_doc'}->setDocumentElement($message->{'ENV'});
  
  my $request = $self->{'_doc'}->toString(2);
  
if ($self->{'verbose'} == 1){
    print "GENERATED SOAP REQUEST: \n";
    print "-------------------------------------------------------------------------------------------------------\n"; 
    print $request;
    print "\n";
  }

  return $self->_CONNECT($request);
}

###WSMAN GET###
sub get{

  my $self = shift;
  my %args = @_;
  my $message = $self->_BUILD_MESSAGE();
  my $ug   = new Data::UUID;
  my $UUID = $ug->create_str(); ###Neue UUID für jeden Vorgang
  
  if ( !$args{"class"}){
    croak "GET ERROR no class submitted to get method"
  }
# TODO: Werte mit defaults initialisieren.

  $message->{'ENV'}->setNamespace(@{[URI_ENUM]},"wsen",0);
  $message->{'ACTION'}->appendTextNode(@{[URI_GET]});
  $message->{'TO'}->appendTextNode("$self->{'proto'}://$self->{'host'}:$self->{'port'}/$self->{'urlpath'}");
  $message->{'MID'}->appendTextNode("uuid:$UUID");

  my $ruri = $message->{'RURI'};
  my $ruritxt = $self->_SETRURI($args{"class"});
  $ruri->setAttributeNS(@{[URI_SOAP]},"mustUnderstand", "true");
  $ruri->setNamespace(@{[URI_WSMAN1]},"wsman",1);
  $ruri->removeChildNodes();
  $ruri->appendTextNode($ruritxt);
  my $selset = $self->_SELECTORSET($args{"SelectorSet"});
  $message->{'HEAD'}->appendChild($selset);

  if (exists $args{"ns"}){
    my $ns = $self->_SELECTORSET( {__cimnamepace => $args{'ns'}});
    $message->{'HEAD'}->appendChild($ns);
  }

  $self->{'_doc'}->setDocumentElement($message->{'ENV'});

 my $request = $self->{'_doc'}->toString(2);

    if ($self->{'verbose'} == 1){
    print "GENERATED SOAP REQUEST: \n";
    print "-------------------------------------------------------------------------------------------------------\n"; 
    print $request;
    print "\n";
  }
  
  return $self->_CONNECT($self->{'_doc'}->toString(2));
}

###WSMAN Invoke###
sub invoke{

  my $self = shift;
  my %args = @_;
  my $message = $self->_BUILD_MESSAGE();
  my $ug   = new Data::UUID;
  my $UUID = $ug->create_str(); ###Neue UUID für jeden Vorgang

  if ( !$args{"class"}){
    croak "INVOKE ERROR no class submitted to invoke method"
  }

  $message->{'RURI'}->setAttributeNS(@{[URI_SOAP]},"mustUnderstand", "true");
  $message->{'RURI'}->setNamespace(@{[URI_WSMAN1]},"wsman",1);
  $message->{'RURI'}->removeChildNodes();

  my $ruri = $message->{'RURI'};
  my $ruritxt = $self->_SETRURI($args{"InvokeClass"});
  $ruri->setAttributeNS(@{[URI_SOAP]},"mustUnderstand", "true");
  $ruri->setNamespace(@{[URI_WSMAN1]},"wsman",1);
  $ruri->removeChildNodes();
  $ruri->appendTextNode($ruritxt);  

  $message->{'ENV'}->setNamespace(@{[URI_ENUM]},"wsen",0);
  $message->{'ACTION'}->appendTextNode("@{[URI_DCIM]}/$args{'InvokeClass'}");
  $message->{'TO'}->appendTextNode("$self->{'proto'}://$self->{'host'}:$self->{'port'}/$self->{'urlpath'}");
  $message->{'MID'}->appendTextNode("uuid:$UUID");

  my $selset = $self->_SELECTORSET($args{"SelectorSet"});
  $message->{'BODY'}->appendChild($selset);

  if (exists $args{"ns"}){
    my $ns = $self->_SELECTORSET( {__cimnamepace => $args{'ns'}});
    $message->{'BODY'}->appendChild($ns);
  }

  my $invoke = $self->{'_doc'}->createElement("$args{'InvokeClass'}_INPUT");
  $invoke->setNamespace("@{[URI_DCIM]}", "p", 1);
  $message->{'BODY'}->appendChild($invoke);
  
  my %Invoke_Input = $args{"Invoke_Input"};
  while ( my ($k,$v) = each %Invoke_Input ) {
    my $invoke_input = $self->{'_doc'}->createElement("$k");
    $invoke_input->setNamespace("@{[URI_DCIM]}", "p", 1);
    $invoke_input->appendTextNode($v);
    $invoke->appendChild($invoke_input);
    }
  
  if (exists $args{"Filter"}){
    my $Filter = $self->{'_doc'}->createElement("Filter");
    $Filter->setNamespace(@{[URI_WSMAN1]},"wsman",1);
    $Filter->setAttribute("Dialect", @{[FILTER]});
    $Filter->appendTextNode($args{"Filter"});
    $message->{'BODY'}->appendChild($Filter);  
  }

my $request = $self->{'_doc'}->toString(2);

    if ($self->{'verbose'} == 1){
    print "GENERATED SOAP REQUEST: \n";
    print "-------------------------------------------------------------------------------------------------------\n"; 
    print $request;
    print "\n";
  }

  return $self->_CONNECT($self->{'_doc'}->toString(2));
}
###Method to Build the std SOAP Request Envelope###
sub _BUILD_MESSAGE{
  
  my $self = shift;
  my $doc = $self->{'_doc'};

  ###Statischer Envelope###

  my $envelope = $doc->createElement("Envelope");
  $envelope->setNamespace(@{[URI_SOAP]} ,"s",1);
  $envelope->setNamespace(@{[URI_ADDR]}, "wsa", 0);
  $envelope->setNamespace(@{[URI_WSMAN1]},"wsman",0);

  ###Statischer Header###

  my $header = $doc->createElement("Header");
  $header->setNamespace(@{[URI_SOAP]} ,"s",1);
  $envelope->appendChild($header);

  my $action = $doc->createElement("Action");
  my $to = $doc->createElement("To");
  my $ruri= $doc->createElement("ResourceURI");
  my $mid = $doc->createElement("MessageID");
  my $rplto  = $doc->createElement("ReplyTo");

  $header->appendChild($action);
  $header->appendChild($to);
  $header->appendChild($ruri);
  $header->appendChild($mid);
  $header->appendChild($rplto);

  ###Statischer Body###

  my $body= $doc->createElement("Body");
  $body->setNamespace(@{[URI_SOAP]} ,"s",1);
  $envelope->appendChild($body);

  ###Statische Aktion###

  $action->setAttributeNS(@{[URI_SOAP]},"mustUnderstand", "true");
  $action->setNamespace(@{[URI_ADDR]}, "wsa", 1);

  ###Statisches TO###

  $to->setAttributeNS(@{[URI_SOAP]},"mustUnderstand", "true");
  $to->setNamespace(@{[URI_ADDR]}, "wsa", 1);

  ###Statisches zur MessageID###

  $mid->setAttributeNS(@{[URI_SOAP]},"mustUnderstand", "true");
  $mid->setNamespace(@{[URI_ADDR]}, "wsa", 1);

  ###Statisches ReplayTo Feld###

  $rplto->setNamespace(@{[URI_ADDR]}, "wsa", 1);
  my $addr = $doc->createElement("Address");
  $rplto->appendChild($addr);
  $addr->setNamespace(@{[URI_ADDR]}, "wsa", 1);
  $addr->appendTextNode('http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous');

  
  return { DOC => $doc, ENV => $envelope, HEAD => $header ,ACTION => $action, TO => $to, RURI => $ruri, MID => $mid, RPLTO => $rplto, BODY => $body, ADDR => $addr}; 
}
###privat Method for Selector-Sets###
sub _SELECTORSET{

  my $self = shift;
  my $args = $_[0];
  my $message = $self->_BUILD_MESSAGE();
  
  
  	
  $selectorset = $self->{'_doc'}->createElement("SelectorSet");
  $selectorset->setNamespace(@{[URI_WSMAN1]},"wsman",1);
  while ( my ($k,$v) = each %{$args} ) {
     my $selector = $self->{'_doc'}->createElement("Selector");
     $selector->setAttribute('Name', $k);
     $selector->setNamespace(@{[URI_WSMAN1]},"wsman",1);
     $selector->appendTextNode($v);
     $selectorset->appendChild($selector);
  }
 
  return $selectorset;
   
}
###privat Method for Class URI generation###
sub _SETRURI{

  my $self = shift;
  my @args = @_;
  my $message = $self->_BUILD_MESSAGE();

  my @RURIP = split /_/, $args[0]; # Komfortfunktion: Bildet RURI aus der Endpoint Reference.	
  if ($RURIP[0] eq "CIM"){
     return ("@{[URI_CIM]} $args[0]");
  } elsif ($RURIP[0] eq "DCIM"){
      return ("@{[URI_DCIM]}$args[0]");
  } elsif ($RURIP[0] eq "OMC"){
      return ("@{[URI_OMC]}$args[0]");
  } elsif ($RURIP[0] eq "VMware"){
      return ("@{[URI_VMWARE]}$args[0]");
  } elsif ($RURIP[0] eq "WIN32"){
      return ("@{[URI_WIN32]}$args[0]");
  } elsif ($RURIP[0] eq "WMI"){
      return ("@{[URI_WMI]}$args[0]");
  } elsif ($RURIP[0] eq "WMICIMV2"){
      return ("@{[URI_WMICIMV2]}$args[0]");
  } elsif ($RURIP[0] eq "CIMV2"){
      return ("@{[URI_CIMV2]}$args[0]");
  } elsif ($RURIP[0] eq "WINRM"){
      return ("@{[URI_WINRM]}$args[0]");
  } elsif ($RURIP[0] eq "WSMAN"){
      return ("@{[URI_WSMAN]}$args[0]");
  } elsif ($RURIP[0] eq "SHELL"){
      return ("@{[URI_SHELL]}$args[0]");
  } else{
      croak "Fehler bei Klasse"
  }

    $args[0] = "";
}


###private Connection Method###
sub _CONNECT{

  my $self = shift;
 

  my $ua = new LWP::UserAgent;
  $ua->credentials("$self->{'host'}/$self->{'urlpath'}", "$self->{'urlpath'}" );
 #$ua->ssl_opts( verify_hostname => 0, verify_peer => 0 ); # Muss noch mit libcrypt::ssleay getestet werden
 #system("export PERL_LWP_SSL_VERIFY_HOSTNAME=0");
  $ua->timeout($self->{'timeout'});

  my $req = new HTTP::Request 'POST',"$self->{'proto'}://$self->{'host'}:$self->{'port'}/$self->{'urlpath'}";
  $req->content_type('application/soap+xml;charset=UTF-8');
  $req->authorization_basic($self->{'user'}, $self->{'passwd'});
  
  if ($self->{'verbose'}){
    print $req->as_string;
  }

  if ( !defined $_[0] ){
    croak "CONNECTION ERROR failed to hand request object to connection method"
  } 


  $req->content($_[0]);
  my $res = $ua->request($req);
  my $result = $res->content();
  if ($res->is_success){
    return $result;
    if ($self->{'verbose'}){
      print $res->as_string;
    }
  } else{
      if ($self->{'verbose'}){
        print $res->as_string;
      }
       if ($result =~ /^\</){
        my $wsmanerror = $self->to_list($result, "s:Fault");
        croak "ERROR WSMan FAULT Object returned: \n", $wsmanerror;
      } else{
        croak "HTTP ERROR: ", $res->status_line();
      }
      
  }
    
  
}

##### Method to Parse WSMAN Responses #####
sub to_list{
  
  my $self = shift;
  my $args = @_;
  
  if ( !defined $_[0] ){
    croak "No XML to parse handed over to to_list method"
  }
    elsif ( !defined $_[1] ){
      croak "No Keytag handed over to to_list method e.g.: s:Fault, n:Items"
  }
    
  
  
  my $parser = XML::LibXML->new();

  my $doc = XML::LibXML->load_xml(
      string => $_[0]
      # parser options ...
  );

  my $root = $doc->documentElement();
  my @nodes = $root->getElementsByTagName($_[1]);
  my $output;
  my @childnodes;
  my @childnodes2;
  my @childnodes3;

  foreach (@nodes){
    #print Dumper($_);
    $output .= "---------------------------------------------";
    $output .= $_->localName;
    $output .= "---------------------------------------------\n";

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
      $output .= "$_->localName hat keine Objekte unterhalb sich selbst!\n";
    }

  }

  #print $output;
  return $output;
  
}


1; # Magic value for Perl Packages;
