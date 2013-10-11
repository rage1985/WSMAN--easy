package WSMAN::Simple::Enum;

use parent WSMAN::Simple;
use Carp;

sub enumerate{
  
  our $self = shift;
  our %args = @_;
  our $ug   = new Data::UUID;
  our $UUID = $ug->create_str(); ###Neue UUID für jeden Vorgang
  
  if ( !$args{"class"}){
    croak "Class fehlt!"
  }
# TODO: Werte mit defaults initialisieren. 
  $envelope->setNamespace(URI_ENUM,"wsen",0);
  $action->appendTextNode("@{[URI_ENUM]}/Enumerate");
  $to->appendTextNode("$self->{'proto'}://$self->{'host'}:$self->{'port'}/$self->{'urlpath'}");
  $MessageID->appendTextNode("uuid:$UUID");


  $self->_SETRURI($args{"class"});

  our $enumeration = $request->createElement("Enumerate");
  $enumeration->setNamespace(URI_ENUM,"wsen",1);
  $body->appendChild($enumeration);

  if (exists $args{"ns"}){
    $self->_SELECTORSET({__cimnamepace => $args{"ns"}});
  }

  if ( exists $args{"optimized"}){
    our $optimize_enum = $request->createElement("OptimizeEnumeration");
    $optimize_enum->setNamespace(URI_WSMAN1,"wsman",1);
    $enumeration->appendChild($optimize_enum);
  }
  if ( exists $args{"maxelements"}){
    our $max_elements = $request->createElement("MaxElements");
    $max_elements->setNamespace(URI_WSMAN1,"wsman",1);
    $max_elements->appendTextNode($args{"maxelements"});
    $enumeration->appendChild($max_elements);
  }
  
  if ( exists $args{"eprmode"}){
    our $epr_mode = $request->createElement("EnumerationMode");
    $epr_mode->setNamespace(URI_WSMAN1,"wsman",1);
    $epr_mode->appendTextNode("EnumerateEPR");
    $enumeration->appendChild($epr_mode);
  }
  
  if (exists $args{"SelectorSet"}){
    $self->WSMAN::Simple::Generic::_SELECTORSET($args{"SelectorSet"});
  }
  
  if (exists $args{"Filter"}){
    our $Filter = $request->createElement("Filter");
    $Filter->setNamespace(URI_WSMAN1,"wsman",1);
    $Filter->setAttribute("Dialect", URI_FILTER);
    $Filter->appendTextNode($args{"Filter"});
    $enumeration->appendChild($Filter);  
  }
  $request->setDocumentElement($envelope);
  
  print $request->toString(2);

  #return $self->_CONNECT($request->toString(2));
}