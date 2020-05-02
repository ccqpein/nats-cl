(defpackage #:nats-cred
  (:use #:CL #:crypto #:cl-base32 #:cl-base64)
  (:export
   #:read-creds-file
   #:sig-nonce)) 

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


;; ed25519 algorithm
(defun sig-nonce (nonce nkey)
  "return signature generated from nonce"
  (let* ((pk (crypto:make-private-key
              :ed25519
              :x (subseq (cl-base32:base32-to-bytes nkey)
                         2 34)))
         (sign (crypto:sign-message pk
                                    (sb-ext:string-to-octets nonce))))
    (cl-base64:usb8-array-to-base64-string sign))
  )

