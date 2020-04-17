;;; subscribe
(let* ((sokt (nats-lib:connect-nats-server "127.0.0.1"))
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
