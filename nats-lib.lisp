(defpackage #:nats-lib
  (:use #:CL #:conditions #:nats-cred)
  (:export
   #:connect-nats-server
   #:pong
   #:nats-info
   #:consume-ping
   #:with-nats-stream
   #:err-or-ok
   #:nats-msg
   #:nats-subs
   #:nats-pub
   #:nats-unsub
   )) 

(in-package #:nats-lib)


(defvar *PING* (format nil "PING~a" #\return))
(defvar *PING-REP* (format nil "PONG~a~a" #\return #\newline))

(defparameter *VERSION* #.(asdf:component-version (asdf:find-system :nats-cl))
              "version")


(defun connect-nats-server (url &key (port 4222) cred)
  "connect to nats servers"
  (declare (simple-string url)) ;;socket-connect' url must be string
  (let* ((sokt (usocket:socket-connect url
                                       port
                                       :element-type 'character
                                       :timeout 30
                                       :nodelay t))
         (info (nats-info (cadr (split-data (read-line (usocket:socket-stream sokt))))))
         jwt nkey)

    (if (gethash "nonce" info)
        (progn
          
          ;; read jwt and nkey no matter server need it or not
          (if cred
              (multiple-value-setq (jwt nkey)
                (nats-cred:read-creds-file (pathname cred)))
              (error "server need authorization, but :cred path is empty"))

          ;; put cred path in info for client side restart
          (setf (gethash "credential" info) cred)
          
          (format (usocket:socket-stream sokt)
                  (nats-connect "jwt" jwt
                                "sig" (nats-cred:sig-nonce (gethash "nonce" info) nkey)))
          
          ;; put connect info to server
          (finish-output (usocket:socket-stream sokt))
          (err-or-ok (read-line (usocket:socket-stream sokt)))))

    ;; consume first PING
    (consume-ping sokt)
    
    ;; return 
    (values (the usocket:usocket sokt) info)
    ))


(defun split-data (str)
  "split data to '(protocol tails)"
  (setf str (subseq str 0 (1- (length str)))) ;; clean the last #\return
  (let ((first-space (position #\Space str)))
    (if (not first-space)
        (list str)
        (list (subseq str 0 first-space)
              (subseq str (1+ first-space)))))  
  )


;; 2020/5/2 OBSOLETE: this function used right after socket connection, answer first PING
;; and return info. Function connect-nats-server take care of this now
(defun post-connection (sokt)
  "parse info and return first pong to server"
  (let ((info (nats-info (cadr (split-data (read-line (usocket:socket-stream sokt))))))
        )
    (consume-ping sokt)
    (values sokt info)))


(defun pong (sokt)
  "answer the ping"
  (format (usocket:socket-stream sokt) *PING-REP*)
  (finish-output (usocket:socket-stream sokt))
  )


;;; INFO {["option_name":option_value],...}
(defun nats-info (str)
  (yason:parse str)
  )


(defun consume-ping (sokt)
  (let* ((stream (usocket:socket-stream sokt))
         (this-line (split-data (read-line stream))))
    (cond ((string= "PING" (car this-line)) (pong sokt))
          (t (warn "Message ~s is not PING" this-line)))))


(defmacro with-nats-stream ((socket data &key init) &body body)
  "read and handler data stream. keyword :init will eval before start to 
read data from socket. @body use \"data\" become the argument binding."
  (let ((stream (gensym)))
    `(let ((,stream (usocket:socket-stream ,socket)))
       ,init
       (unwind-protect
            (do* ((,data (read-line ,stream) (read-line ,stream))
                  )
                 (nil)
              ,@body
              )
         (progn
           (usocket:socket-close ,socket))))))


;;; +OK/ERR
(defun err-or-ok (str)
  "if ok return nil, else give error. this function only use when
response mighe be ok OR err. if you know it might be err with something else.
make error directly"
  (let* ((pre-ss (split-data str))
         (ss (car pre-ss))
         (err-msg (cadr pre-ss)))
    (cond ((string= "+OK" ss)
           nil)
          (t (error (conditions:get-conditions err-msg)
                    :error-message err-msg)) ; re-write error-message for giving more details
          )))


;;; MSG <subject> <sid> [reply-to] <#bytes>\r\n[payload]\r\n
(defun nats-msg (str)
  "second return value used for payload"
  (let (reply-to
        bytes
        (data (str:split-omit-nulls #\Space str)))
    (if (> (length data) 3)
        (setf reply-to (nth 2 data)
              bytes (parse-integer (nth 3 data)))
        (setf bytes (parse-integer (nth 2 data))))
    (values reply-to
            (make-array bytes :element-type 'character :fill-pointer 0)))
  )


;;; assume sokt is empty
;;; SUB <subject> [queue group] <sid>\r\n
(defun nats-subs (sokt subject sid consume-func &key queue-group info)
  (declare (usocket:usocket sokt)
           (simple-string subject)
           (fixnum sid))

  (let ((connect-urls (if info (gethash "connect_urls" info) '())) ;; list of servers' ip
        ) ;; used to count times of handle-bind auto restart
    (tagbody
     start
       ;; subscribe
       (format (usocket:socket-stream sokt)
               "sub ~a ~@[~a ~]~a~a~a" subject queue-group sid #\return #\newline)
       
       ;; ensure command go to server
       (finish-output (usocket:socket-stream sokt))

       ;; ensure successful
       (let ((this-line (read-line (usocket:socket-stream sokt))))
         (err-or-ok this-line))

       (format t "subscribe ~a successful.~%" subject)
     
       (let (flag
             reply-to
             msg)
         (with-nats-stream (sokt ss)
           (let* ((data (split-data ss))
                  (head (car data))
                  (tail (cadr data)))
             (if flag
                 (progn
                   (setf flag nil
                         reply-to nil)
                   (funcall consume-func head)) ;; consume message
               
                 ;; handle message
                 (cond 
                   ((string= "MSG" head)
                    (progn (setf flag t)
                           (multiple-value-setq (reply-to msg) ;; msg does not used
                             (nats-msg tail))))
                 
                   ((string= "PING" head)
                    (pong sokt))

                   ((string= "INFO" head)
                    ;; update info and connect-urls
                    (setf info (nats-info tail))
                    (dolist (u (gethash "connect_urls" info)) (pushnew a connect-urls))
                    )

                   ((string= "-ERR" head)
                    (restart-case
                        (error (conditions:get-conditions tail)
                               :error-message tail)
                      (try-to-restart ()
                        :report "restart this subscription by reconnect socket with stored info"
                        (go restart))
                      );;:= TODO: restart with input value
                    )
                 
                   (t (error (conditions:get-conditions tail)
                             :error-message tail)))))))
     
     restart
       (if (and (not info) (not connect-urls))
           (error "no binding of 'info' or connect-urls, cannot restart"))
       ;;:= MAYBE: can accept host/port input
       
       (multiple-value-setq (sokt info)
         (if info
             (connect-nats-server (concatenate 'string
                                               (gethash "host" info)) ;host isn't simple string
                                  :port (gethash "port" info)
                                  :cred (gethash "credential" info))

             ;;:= MARK: else block cannot connect with cred
             (let ((temp (str:split #\: (car connect-urls))))
               (connect-nats-server (car temp) :port (cadr temp))) 
             ))
       
       (go start)
       ))
  )


;;; CONNECT {["option_name":option_value],...}
(defun nats-connect (&rest pairs)
  (let ((table (make-hash-table)))
    ;; put init var
    (loop
      for (k v) in '(("verbose" nil)
                     ("pedantic" nil)
                     ("tls_required" nil)
                     ("name" "")
                     ("lang" "common-lisp")
                     ("version" #.*VERSION*)
                     ("protocol" 1)     ;;:= TODO: this maybe change 
                     ("echo" t))
      do (setf (gethash k table) v))

    ;; update with pairs
    (if (not (evenp (length pairs))) (error "~a length is not even" pairs))

    (do ((k (car pairs) (car pairs))
         (v (cadr pairs) (cadr pairs)))
        ((not pairs))
      (setf (gethash k table) v
            pairs (cddr pairs)))

    ;; return str, with CONNECT at beginning
    (format nil "CONNECT ~a~a~a"
            (with-output-to-string (s)
                (yason:encode table s))
            #\return #\newline)
    ))


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
    (err-or-ok (read-line stream))
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
    (err-or-ok (read-line stream))
    ))


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

