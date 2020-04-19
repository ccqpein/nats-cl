(defvar *ERRORS-MAP*
  '(("Unknown Protocol Operation" .
     "Unknown protocol error")
                       
    ("Attempted To Connect To Route Port" .
     "Client attempted to connect to a route port instead of the client port")
                       
    ("Authorization Violation" .
     "Client failed to authenticate to the server with credentials specified in the CONNECT message")
                       
    ("Authorization Timeout" .
     "Client took too long to authenticate to the server after establishing a connection (default 1 second)")
    ("Invalid Client Protocol" .
     "Client specified an invalid protocol version in the CONNECT message")
    
    ("Maximum Control Line Exceeded" .
     "Message destination subject and reply subject length exceeded the maximum control line value specified by the max_control_line server option.  The default is 1024 bytes.")
    
    ("Parser Error" .
     "Cannot parse the protocol message sent by the client")
    
    ("Secure Connection - TLS Required" .
     "The server requires TLS and the client does not have TLS enabled.")
    
    ("Stale Connection" .
     "The server hasn't received a message from the client, including a PONG in too long.")
    
    ("Maximum Connections Exceeded" .
     "This error is sent by the server when creating a new connection and the server has exceeded the maximum number of connections specified by the max_connections server option.  The default is 64k.")
    
    ("Slow Consumer" .
     "The server pending data size for the connection has reached the maximum size (default 10MB).")
    
    ("Maximum Payload Violation" .
     "Client attempted to publish a message with a payload size that exceeds the max_payload size configured on the server. This value is supplied to the client upon connection in the initial INFO message. The client is expected to do proper accounting of byte size to be sent to the server in order to handle this error synchronously.")
    
    ("Invalid Subject" .
     "Client sent a malformed subject (e.g. sub foo. 90)")
    
    ("Permissions Violation for Subscription to <subject>" .
     "The user specified in the CONNECT message does not have permission to subscribe to the subject.")
    
    ("Permissions Violation for Publish to <subject>" .
     "The user specified in the CONNECT message does not have permissions to publish to the subject.")
    ))


