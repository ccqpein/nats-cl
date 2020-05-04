;;; connect server
(let ((sokt (connect-nats-server "127.0.0.1")))
  (read-nats-stream-answer-ping sokt))


;;; connect server and get info
(multiple-value-bind (sokt info)
    (connect-nats-server "127.0.0.1")
  (format t "hashtable info ~a~%" info)
  (read-nats-stream-answer-ping sokt))


;;; subscribe
(let* (sokt
       info
       )
  (multiple-value-setq (sokt info) (connect-nats-server "127.0.0.1"))
  (nats-subs sokt
             "test"
             1
             (lambda (x) (progn (print "inner consume function") (print x)))
             :info info
             ))

;;; with queue group
(let* (sokt 
       info
       )
  (multiple-value-setq (sokt info) (connect-nats-server "127.0.0.1"))
  (nats-subs sokt
             "test"
             1
             (lambda (x) (progn (print "inner consume function") (print x)))
             :info info
             :queue-group 23
             ))


;;; publish message
(let* (sokt
       info
       )
  (multiple-value-setq (sokt info) (connect-nats-server "127.0.0.1"))
  (nats-pub sokt
            "test"
            5
            "hello"
            ))


;;; write you own message handler
(let (sokt 
      info)
  (multiple-value-setq (sokt info) (connect-nats-server "127.0.0.1"))
  ;; with-nats-stream macro will read message in stream one by one
  ;; then binding message with data which used in body
  ;; sokt will close when with-nats-stream macro finish
  (with-nats-stream (sokt data)
    (format t "~a~%" data)))


;;; Connect with creds file
(multiple-value-bind (sokt info)
    (connect-nats-server "127.0.0.1" :cred "your creds file")
  (read-nats-stream-answer-ping sokt))

