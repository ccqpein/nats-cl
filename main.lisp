(ql:quickload "usocket")


(defstruct nats-connection)


(defun connect-nats-server (url &key (port 4222))
  "connect to nats servers"
  (declare (simple-string url))
  (let ((socket (usocket:socket-connect url
                                        port
                                        :element-type 'character
                                        :timeout 30
                                        :nodelay t)))
    (the usocket:usocket socket)
    ))


;;:= TODO: need json parser
;;; INFO {["option_name":option_value],...}
(defun nats-info (sokt)
  )


;;; SUB <subject> [queue group] <sid>\r\n
(defun nats-subs (sokt subject sid &key queue-group)
  (declare (usocket:usocket sokt)
           (simple-string subject)
           (fixnum sid))
  
  (format (usocket:socket-stream sokt)
          "sub ~a ~@[~a ~]~a~a~a" subject queue-group sid #\return #\newline)
  (finish-output (usocket:socket-stream sokt))
  )


;;:= TODO: json parser
;;; CONNECT {["option_name":option_value],...}
(defun nats-connect ())


;;; PUB <subject> [reply-to] <#bytes>\r\n[payload]\r\n
(defun nats-pub (sokt subject bytes-size &optional msg &key reply-to)
  (declare (usocket:usocket sokt)
           (simple-string subject)
           (fixnum bytes-size))

  (format (usocket:socket-stream sokt)
          "pub ~a ~@[~a ~]~a~a~a~@[~a~]~a~a"
          subject reply-to bytes-size #\return #\newline
          msg #\return #\newline)

  (finish-output (usocket:socket-stream sokt))
  )


;;; UNSUB <sid> [max_msgs]
(defun nats-unsub (sokt sid &key max-msgs)
  (declare (usocket:usocket sokt)
           (fixnum sid))

  (format (usocket:socket-stream sokt)
          "unsub ~a~@[ ~a~]~a~a"
          sid max-msgs #\return #\newline)
  
  (finish-output (usocket:socket-stream sokt))
  )


;;; MSG <subject> <sid> [reply-to] <#bytes>\r\n[payload]\r\n
(defun nats-msg (sokt subject sid bytes-size &optional msg &key reply-to)
  (declare (usocket:usocket sokt)
           (simple-string subject)
           (fixnum sid bytes-size))

  (format (usocket:socket-stream sokt)
          "msg ~a ~a ~@[~a ~]~a~a~a~@[~a~]~a~a"
          subject sid reply-to bytes-size #\return #\newline
          msg #\return #\newline)
  
  (finish-output (usocket:socket-stream sokt))
  )

;;;:= TODO: PING\r\n
;;;:= TODO: PONG\r\n
(defun read-stream (sokt)
  )

;;;:= TODO: +OK/ERR
