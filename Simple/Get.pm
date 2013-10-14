package WSMAN::Simple::Get;

push ( @INC,"/home/sascha/bin/git/WSMAN/");
use WSMAN::Simple;
use Carp;

@ISA = qw( _SELECTORSET _CONNECT _PARSER);

sub get{

  my $class = shift;
  my $self = bless {
  }, $class;
  
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