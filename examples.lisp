;;; subscribe
(let* ((sokt (connect-nats-server "127.0.0.1"))
       info
       )
  (multiple-value-setq (sokt info) (post-connection sokt))
  (nats-subs sokt
             "test"
             1
             (lambda (x) (progn (print "inner consume function") (print x)))
             :info info
             ))

;;; with queue group
(let* ((sokt (connect-nats-server "127.0.0.1"))
       info
       )
  (multiple-value-setq (sokt info) (post-connection sokt))
  (nats-subs sokt
             "test"
             1
             (lambda (x) (progn (print "inner consume function") (print x)))
             :info info
             :queue-group 23
             ))


;;; publish message
(let* ((sokt (connect-nats-server "127.0.0.1"))
       info
       )
  (multiple-value-setq (sokt info) (post-connection sokt))
  (nats-pub sokt
            "test"
            5
            "hello"
            ))


;;; write you own message handler
(let ((sokt (connect-nats-server "127.0.0.1"))
      info)
  (multiple-value-setq (sokt info) (post-connection sokt))
  ;; with-nats-stream macro will read message in stream one by one
  ;; then binding message with data which used in body
  ;; sokt will close when with-nats-stream macro finish
  (with-nats-stream (sokt data)
    (format t "~a~%" data)))


;;; Connect with creds file

