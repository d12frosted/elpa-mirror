To use the SOAP client, you first need to load the WSDL document for the
service you want to access, using `soap-load-wsdl-from-url'.  A WSDL
document describes the available operations of the SOAP service, how their
parameters and responses are encoded.  To invoke operations, you use the
`soap-invoke' method passing it the WSDL, the service name, the operation
you wish to invoke and any required parameters.

Ideally, the service you want to access will have some documentation about
the operations it supports.  If it does not, you can try using
`soap-inspect' to browse the WSDL document and see the available operations
and their parameters.