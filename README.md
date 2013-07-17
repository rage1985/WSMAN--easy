WSMAN--easy
===========

Object oriented interface to DMTF´s WSMAN

## Description



## Prequisits


Data::UUID

WWW::Curl::Easy

MIME::Base64

Data::Dumper (Will be removed soon)

XML::LibXML

XML::Simple  (Will also be removed soon)



## Installation

Copy the Module (.pm) to the Folder of your Script or into a location in your @INC variable

## Methods

### WSMAN::easy->new()

```perl
my $WSMAN = WSMAN::easy->new(

	"ost"		=>	"$hostname",
	"port"		=>	"$port",
	"user"		=>	"$username",	
	"passwd"	=>	"$password",
	"urlpath"	=>	"$urlpath",
	"proto"		=>	"$protocol",
	"verbose"	=>	"$verbosemode"
	
);
```

This Method will create a new WSMan Session Object that stores connection specific information for use in later WSMAN Operation Methods.

##### host

Address of the remote host which runs the WSMAN provider.
Can be either IPv4, FQDN or IPv6 in Square brackets.

##### port

Port of the remote on which the WSMAN-Provider is configured.

##### user

Username of an user with sufficient rights to connect and perform WSMAN Operations on the remote host.

##### passwd

Passphrase of the User above mentioned User.

##### urlpath

The url path under which the specific WSMAN-Provider is reachable.
For example:

wsmanserver.org/wsman (/wsman would be your urlpath)

The first / is always given so in this case you would just hand over wsman to the variable.

##### proto

The protocol the server is listening to. Can be either http or https.

##### verbose

Set the verbose mode of the module. This will you the created requests and the connection information from Curl.
Can be either 0, 1 or true, false.

### WSMAN::easy->identify()

```perl
my $identify = $WSMAN->identify()	
```

Performs an WSMAN-Identify Operation on the remote specified by the "new" Object.
There are no arguments to be handed over.

### WSMAN::easy->enumerate()

```perl
my $enum = $WSMAN->enumerate(

	"class"			=>	"$class",
	"ns"			=>	"$namespace",
	"optimized"		=>	"$optimized",
	"maxelements"	=>	"$maxelements",
	"Filter"		=>	"Select * from $class where $param=$expr",
	"eprmode"		=>	"$eprmode",
	"SelectorSet"	=>	{"$selector" => "$expr"}

);


```

### WSMAN::easy->get()

```perl

my $get = $WSMAN->get(

	"class"			=>	"$class",
	"ns"			=>	"$namespace",
	"SelectorSet"	=>	{"InstanceID" => "$param => $expr"}

);
```


### WSMAN::easy->invoke() 

```perl

my $invoke = $WSMAN->invoke(

	"class"			=>	"$class",
	"InvokeClass"   =>	"$invokeclass",
	"SelectorSet"   =>	{"$param" => "$expr"},
	"Invoke_Input"	=>	{"$param" => "$input"}
	
);
	
```






