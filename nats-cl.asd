;;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; Base: 10 -*-

(defpackage #:nats-cl-asdf
  (:use #:CL #:asdf))


(in-package #:nats-cl-asdf)


(defsystem nats-cl
  :name "nats-cl"
  :version "0.5"
  :author "ccQpein"
  :maintainer "ccQpein"
  
  :defsystem-depends-on ("usocket" "yason" "str" "ironclad" "cl-base32" "cl-base64")
  
  :components ((:file "conditions")
               (:file "credentials")
               (:file "nats-lib"
                :depends-on ("conditions" "credentials")))
  )
