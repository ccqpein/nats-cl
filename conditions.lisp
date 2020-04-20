(defpackage #:conditions
  (:use #:CL)
  (:export #:*ERRORS*
           #:*ERROR-MAP*))

(in-package #:conditions)

;;; Macro will expand first and run in toplevel, and macro need
;;; *ERRORS* and *ERROR-MAP*, so these two global var should run in
;;; compilation time
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defvar *ERRORS*
    '((unknown-protocol 
       ("Unknown Protocol Operation" .
        "Unknown protocol error"))
      
      (connent-to-route-port 
       ("Attempted To Connect To Route Port" .
        "Client attempted to connect to a route port instead of the client port"))
      
      (authorization-violation 
       ("Authorization Violation" .
        "Client failed to authenticate to the server with credentials specified in the CONNECT message"))
      
      (authorization-timeout 
       ("Authorization Timeout" .
        "Client took too long to authenticate to the server after establishing a connection (default 1 second)"))
      
      (invalid-client-protocol 
       ("Invalid Client Protocol" .
        "Client specified an invalid protocol version in the CONNECT message"))
      
      (maximum-control-line-exceeded 
       ("Maximum Control Line Exceeded" .
        "Message destination subject and reply subject length exceeded the maximum control line value specified by the max_control_line server option.  The default is 1024 bytes."))
      
      (parser-error
       ("Parser Error" .
        "Cannot parse the protocol message sent by the client"))
      
      (TLS-required 
       ("Secure Connection - TLS Required" .
        "The server requires TLS and the client does not have TLS enabled."))
      
      (stale-connection 
       ("Stale Connection" .
        "The server hasn't received a message from the client, including a PONG in too long."))
      
      (maximum-connections-exceeded 
       ("Maximum Connections Exceeded" .
        "This error is sent by the server when creating a new connection and the server has exceeded the maximum number of connections specified by the max_connections server option.  The default is 64k."))
      
      (slow-consumer 
       ("Slow Consumer" .
        "The server pending data size for the connection has reached the maximum size (default 10MB)."))
      
      (maximum-payload-violation 
       ("Maximum Payload Violation" .
        "Client attempted to publish a message with a payload size that exceeds the max_payload size configured on the server. This value is supplied to the client upon connection in the initial INFO message. The client is expected to do proper accounting of byte size to be sent to the server in order to handle this error synchronously."))
      
      (invalid-subject 
       ("Invalid Subject" .
        "Client sent a malformed subject (e.g. sub foo. 90)"))
      
      (permissions-violation-for-sub 
       ("Permissions Violation for Subscription to <subject>" .
        "The user specified in the CONNECT message does not have permission to subscribe to the subject."))
      
      (permissions-violation-for-pub 
       ("Permissions Violation for Publish to <subject>" .
        "The user specified in the CONNECT message does not have permissions to publish to the subject."))
      ))

  (defvar *ERROR-MAP* (make-hash-table :test #'equal)))

(defmacro auto-make-conditions ()
  (loop
    for e in *errors*
    collect (let ((symbol (car e))
                  (msg (caadr e))
                  (detail (cdadr e)))
              (setf (gethash msg *ERROR-MAP*) symbol) ;; insert condition in *error-map*
              (export symbol)
              `(define-condition ,symbol (error)
                 ()
                 (:documentation ,detail)))
      into result
    finally (return (cons 'progn result))
    ))

;;; expand macro in toplevel, auto make all conditions.
(auto-make-conditions)
