(ql:quickload "usocket")


(defvar *PING* (format nil "PING~a" #\return))
(defvar *PING-REP* (format nil "PONG~a~a" #\return #\newline))

(defvar *PONG* (format nil "PONG~a" #\return))
;;(defvar *PONG-REP* (format nil "PONG~a~a" #\return #\newline))


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


;;:= keep reading data from connection socket and send data to outside stream
;;:= should have ability to answer pong when receive ping
;;:= TODO: need error handle
(defun read-nats-stream (sokt &key output)
  (let ((stream (usocket:socket-stream sokt)))
    (loop
      do (format (if (not output) 't output) "~A~%" (read-line stream)))
    ))


(defun read-nats-stream-answer-ping (sokt &key output)
  (let ((stream (usocket:socket-stream sokt)))
    (loop
      do (let ((data (read-line stream)))
           (format (if (not output) 't output) "~A~%" data)
           (if (string= data *PING*)
               (progn
                 (format stream "~a" *PING-REP*)
                 (format (if (not output) 't output) "~a" *PING-REP*)))
           ))
    ))

;;:= TEST: (let ((conn (connect-nats-server "localhost"))) (unwind-protect (read-nats-stream-answer-ping conn) (usocket:socket-close conn)))


;;;:= TODO: +OK/ERR
