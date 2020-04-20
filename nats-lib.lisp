(defpackage #:nats-lib
  (:use #:CL #:conditions)
  (:export #:*PING*))

(in-package #:nats-lib)


(defvar *PING* (format nil "PING~a" #\return))
(defvar *PING-REP* (format nil "PONG~a~a" #\return #\newline))


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


(defun post-connection (sokt)
  "parse info and return first pong to server"
  (let ((info (nats-info (cadr (split-data (read-line (usocket:socket-stream sokt))))))
        )
    (consume-ping sokt)
    (values sokt info)))


;;; INFO {["option_name":option_value],...}
(defun nats-info (str)
  (yason:parse str)
  )


(defun consume-ping (sokt)
  (let* ((stream (usocket:socket-stream sokt))
         (this-line (car (split-data (read-line stream)))))
    (cond ((string= "PING" this-line) (pong sokt))
          (t "")))) ;;:= need some condition


;;; assume sokt is empty
;;; SUB <subject> [queue group] <sid>\r\n
(defun nats-subs (sokt subject sid consume-func &key queue-group info)
  (declare (usocket:usocket sokt)
           (simple-string subject)
           (fixnum sid))

  (tagbody
   start
     ;; subscribe
     (format (usocket:socket-stream sokt)
             "sub ~a ~@[~a ~]~a~a~a" subject queue-group sid #\return #\newline)

     ;; ensure command go to server
     (finish-output (usocket:socket-stream sokt))

     ;; ensure successful
     (let ((this-line (read-line (usocket:socket-stream sokt))))
       (if (string/= "+OK" (car (split-data this-line)))
           (return-from nats-subs (format nil "cannot subs: ~a~%" this-line)))) ;;:= should be contition

     (format t "subscribe ~a successful.~%" subject)
     
     (let (flag
           reply-to
           msg)
       (with-nats-stream (sokt ss)
         (let* ((data (split-data ss))
                (head (car data)))
           (if flag
               (progn
                 (setf flag nil
                       reply-to nil)
                 (funcall consume-func head)) ;; consume message
               
               ;; watch
               (cond 
                 ((string= "MSG" head)
                  (progn (setf flag t)
                         (multiple-value-setq (reply-to msg) ;;:= msg does not used
                           (apply #'nats-msg (cdr data)))))
                 
                 ((string= "PING" head)
                  (progn (pong sokt)
                         (format t *PING-REP*))) ;; return pong to output for debug
                 
                 ((string= "-ERR" head)
                  (format t "close~%") ;;:= should be condition too
                  (go restart))
                 
                 (t (format t "Unmatched data: ~a~%" data)))))))

   restart
     (if (not info) (return-from nats-subs "no info input, no host, cannot reconnect")) ;;:= need to be condition
     (setf sokt (connect-nats-server (concatenate 'string (gethash "host" info))
                                     :port (gethash "port" info)))

     (multiple-value-setq (sokt info) (post-connection sokt))
     
     (go start)
     )
  )


;;;:= TODO: CONNECT {["option_name":option_value],...}
(defun nats-connect ())


;;; PUB <subject> [reply-to] <#bytes>\r\n[payload]\r\n
(defun nats-pub (sokt subject bytes-size &optional msg &key reply-to)
  (declare (usocket:usocket sokt)
           (simple-string subject)
           (fixnum bytes-size))

  (let ((stream (usocket:socket-stream sokt)))
    (format stream
            "pub ~a ~@[~a ~]~a~a~a~@[~a~]~a~a"
            subject reply-to bytes-size #\return #\newline
            msg #\return #\newline)

    (finish-output stream)
    ;; ensure it is successfully
    (if (err-or-ok (read-line stream)) "publish wrong") ;;:= TODO: need to be condition
    ))


;;; UNSUB <sid> [max_msgs]
(defun nats-unsub (sokt sid &key max-msgs)
  (declare (usocket:usocket sokt)
           (fixnum sid))

  (let ((stream (usocket:socket-stream sokt)))
    (format stream
            "unsub ~a~@[ ~a~]~a~a"
            sid max-msgs #\return #\newline)
    
    (finish-output stream)
    ;; ensure it is successfully
    (if (err-or-ok (read-line stream)) "publish wrong") ;;:= TODO: need to be condition
    ))


;;; MSG <subject> <sid> [reply-to] <#bytes>\r\n[payload]\r\n
(defun nats-msg (str)
  "second return value used for payload"
  (let (reply-to
        bytes
        (data (split-sequence:split-sequence #\Space str)))
    (if (> (length data) 3)
        (setf reply-to (nth 2 data)
              bytes (parse-integer (nth 3 data)))
        (setf bytes (parse-integer (nth 2 data))))
    (values reply-to (make-array bytes :element-type 'character :fill-pointer 0)))
  )


;;; keep reading data from connection socket and send data to outside stream
(defun read-nats-stream (sokt &key output)
  "just print out nats stream one by one"
  (let ((stream (usocket:socket-stream sokt)))
    (loop
      do (format (if (not output)
                     't
                     output)
                 "~A~%"
                 (let ((this-line (read-line stream)))
                   (subseq this-line 0 (1- (length this-line))))))
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


(defmacro with-nats-stream ((socket data &key init) &body body)
  "read and handler data stream. keyword :init will eval before start to 
read data from socket. @body use \"data\" become the argument binding."
  (let ((stream (gensym)))
    `(let ((,stream (usocket:socket-stream ,socket)))
       ,init
       (unwind-protect
            (handler-case
                (do* ((,data (read-line ,stream) (read-line ,stream))
                      )
                     (nil)
                  ,@body
                  )
              (end-of-file (c) (format t "socket has closed: ~a~%" c)))
         (progn
           (usocket:socket-close ,socket))))))


(defun split-data (str)
  "split data with '(protocol tails)"
  (setf str (subseq str 0 (1- (length str)))) ;; clean the last #\return
  (let ((first-space (position #\Space str)))
    (if (not first-space)
        (list str)
        (list (subseq str 0 first-space)
              (subseq str (1+ first-space)))))  
  )


(defun pong (sokt)
  "answer the ping"
  (format (usocket:socket-stream sokt) *PING-REP*)
  (finish-output (usocket:socket-stream sokt))
  )


;;; +OK/ERR
(defun err-or-ok (str)
  "if ok return nil, if err return the condition of err"
  (let* ((pre-ss (split-data str))
         (ss (car pre-ss))
         (err-msg (cadr pre-ss)))
    (cond ((string= "+OK" ss)
           nil)
          (t err-msg) ;;:= TODO: should be condition
      )))
