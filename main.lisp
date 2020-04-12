(ql:quickload "usocket")
(ql:quickload "yason")
(ql:quickload "split-sequence")


(defvar *PING* (format nil "PING~a" #\return))
(defvar *PING-REP* (format nil "PONG~a~a" #\return #\newline))
(defvar *PONG* (format nil "PONG~a" #\return))


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


;;; INFO {["option_name":option_value],...}
(defun nats-info (str)
  (the hashtable (yason:parse str))
  )


;;; SUB <subject> [queue group] <sid>\r\n
(defun nats-subs (sokt subject sid &key queue-group)
  (declare (usocket:usocket sokt)
           (simple-string subject)
           (fixnum sid))

  (usocket:wait-for-input sokt :timeout 15)
  
  (format (usocket:socket-stream sokt)
          "sub ~a ~@[~a ~]~a~a~a" subject queue-group sid #\return #\newline)
  (finish-output (usocket:socket-stream sokt))
  )


;;;:= TODO: CONNECT {["option_name":option_value],...}
(defun nats-connect ())


;;; PUB <subject> [reply-to] <#bytes>\r\n[payload]\r\n
(defun nats-pub (sokt subject bytes-size &optional msg &key reply-to)
  (declare (usocket:usocket sokt)
           (simple-string subject)
           (fixnum bytes-size))

  (usocket:wait-for-input sokt :timeout 15)
  
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

  (usocket:wait-for-input sokt :timeout 15)
  
  (format (usocket:socket-stream sokt)
          "unsub ~a~@[ ~a~]~a~a"
          sid max-msgs #\return #\newline)
  
  (finish-output (usocket:socket-stream sokt))
  )


;;; MSG <subject> <sid> [reply-to] <#bytes>\r\n[payload]\r\n
(defun nats-msg (subject sid &rest tail)
  "second return value used for payload"
  (let (reply-to
        bytes)
    (if (> (length tail) 1)
        (setf reply-to (car tail)
              bytes (parse-integer (cadr tail)))
        (setf bytes (parse-integer (car tail))))
    (values reply-to (make-array bytes :element-type 'character :fill-pointer 0)))
  )


;;:= keep reading data from connection socket and send data to outside stream
;;:= should have ability to answer pong when receive ping
(defun read-nats-stream (sokt &key output)
  (usocket:wait-for-input sokt :timeout 15)
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
                 (finish-output stream)
                 (format (if (not output) 't output) "~a" *PING-REP*)))
           ))
    ))


;;;:= TODO: +OK/ERR
