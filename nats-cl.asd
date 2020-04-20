;;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; Base: 10 -*-

(defpackage #:nats-cl-asdf
  (:use #:CL #:asdf))


(in-package #:nats-cl-asdf)


(defsystem nats-cl
  :name "nats-cl"
  :version "0.5"
  :author "ccQpein"
  :maintainer "ccQpein"
  
  :defsystem-depends-on ("usocket" "yason" "split-sequence")
  
  :components ((:file "conditions")
               (:file "nats-lib"
                :depends-on ("conditions")))
  )

