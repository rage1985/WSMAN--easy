package WSMAN::Simple::Identify;

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

1;