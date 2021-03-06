WSMAN--easy
===========

Object oriented interface to DMTF´s WSMAN

BETA 
----
##### Caveeats

This module is not finished yet. DMTF compliance is not given yet.

You may experience missing features, unexpected behavior.

Please report everything via the issues function.

The PUT Method is not implemented yet.

Some Namespace for specific operations are not implemented yet.


## Description

The WSMAN::easy module implemets an object oriented interface to the Web Services Management (WSMAN) Protocol. 
Perl applications can use the module to retrieve or update information on a remote host using the WSMAN protocol.
The WSMAN::easy module assumes that the user has a basic understanding of the Web Services Management Protocol and related network management concepts.

The module will be WSMAN 1.1.1 compliant when out of beta. See http://www.dmtf.org/sites/default/files/standards/documents/DSP0226_1.1.1.pdf

## Prequisits

Data::UUID

LWP::UserAgent

XML::LibXML

XML::Simple


## Installation

Copy the Module (.pm) to the Folder of your Script or into a location in your @INC variable.

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
	"verbose"	=>	"$verbosemode",
	"timeout"	=>	"$timeout"
	
);
```

### WSMAN::easy->identify()

```perl
my $identify = $WSMAN->identify()	
```


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
### WSMAN::easy->to_list() 

```perl

my $results = $WSMAN->to_list($response, "w:ITEMS");


```


## Author

Sascha Schaal





