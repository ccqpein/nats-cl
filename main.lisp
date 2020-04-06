(ql:quickload "usocket")

(defun create-client ()
  (let ((socket (usocket:socket-connect "127.0.0.1" 4222 :element-type 'character)))
    (unwind-protect 
	     (progn
	       (usocket:wait-for-input socket)
	       (format t "1: ~A~%" (read-line (usocket:socket-stream socket)))
           (format t "2: ~A~%" (read-line (usocket:socket-stream socket)))

           (format (usocket:socket-stream socket) "pub test1 5~a~a" #\return #\newline)
           (finish-output (usocket:socket-stream socket))

           (format (usocket:socket-stream socket) "yoyoa~a~a" #\return #\newline)
           (finish-output (usocket:socket-stream socket))

           ;;(format (usocket:socket-stream socket) "PING~%")
           ;;(finish-output (usocket:socket-stream socket))

           (format t "here?: ~A~%" (read-line (usocket:socket-stream socket))))
      (usocket:socket-close socket))))
