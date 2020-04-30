(defpackage #:nats-cred
  (:use #:CL)) 

(in-package #:nats-cred)

(defun read-creds-file (filepath)
  "read creds file and return JWT and nkey"
  (with-open-file (s filepath)
    (loop
      with flag and jwt and nkey
      for line = (read-line s nil)
      while line
      do (cond ((string= line "-----BEGIN NATS USER JWT-----")
                (setf flag 'jwt)) ;; read jwt
               
               ((or (string= line "------END NATS USER JWT------")
                    (string= line "------END USER NKEY SEED------"))
                (setf flag nil))

               ((string= line "-----BEGIN USER NKEY SEED-----")
                (setf flag 'nkey))

               (t
                (case flag
                  (jwt (setf jwt line))
                  (nkey (setf nkey line))
                  (otherwise nil))))
      finally (return (values jwt nkey))
     )))

(defun sig-nonce (nonce)
  "return signature generated from nonce"
  )

