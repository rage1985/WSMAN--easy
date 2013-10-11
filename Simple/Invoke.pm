package WSMAN::Simple::Invoke;

sub invoke{

  our $self = shift;
  our $args = @_;
  our $ug   = new Data::UUID;
  our $UUID = $ug->create_str(); ###Neue UUID für jeden Vorgang

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

  our $invoke = $request->createElement("$args->{'InvokeClass'}_INPUT");
  $invoke->setNamespace(URI_DCIM, "p", 1);
  $body->appendChild($invoke);
  
  our %Invoke_Input = $args->{"Invoke_Input"};
  while ( our ($k,$v) = each %Invoke_Input ) {
    our $invoke_input = $request->createElement("$k");
    $invoke_input->setNamespace(URI_DCIM, "p", 1);
    $invoke_input->appendTextNode($v);
    $invoke->appendChild($invoke_input);
    }
  
  if (exists $args->{"Filter"}){
    our $Filter = $request->createElement("Filter");
    $Filter->setNamespace(URI_WSMAN1,"wsman",1);
    $Filter->setAttribute("Dialect", URI_FILTER);
    $Filter->appendTextNode($args->{"Filter"});
    $body->appendChild($Filter);  
  }

  $request->setDocumentElement($envelope);
  
  print $request->toString(2);

  #return $self->_CONNECT($request->toString(2));
}