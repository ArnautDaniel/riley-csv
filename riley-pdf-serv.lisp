(progn (ql:quickload '(usocket) :silent t))

(defpackage :riley-pdf-serv
  (:use :cl))
(in-package :riley-pdf-serv)
#| 
I still have 2 more parts of this to write
so I'm borrowing this tcp code to base off of
and eliminate some of the work
https://gist.github.com/traut/6bf71d0da54493e6f22eb3d00671f2a9
|#

(defun send-text-to-socket (text socket)
  (let ((socket-stream (usocket:socket-stream socket)))
    (format socket-stream "~a " (array-total-size text))
    (dotimes (temp (array-total-size text) temp)
      (format socket-stream "~a " (aref text temp)))
    (format socket-stream "~%")
					; adding a line break at the end for prettiness
    
    (force-output socket-stream)))


(defun logger (text &rest args)
  "Simple wrapper around format func to simplify logging"
  (apply 'format (append (list t (concatenate 'string text "~%")) args)))

(defun file-string (path)
  (with-open-file (stream path :element-type '(unsigned-byte 16))
    (let ((data (make-array (file-length stream) :element-type '(unsigned-byte 16))))
      (read-sequence data stream)
      data)))

(defun close-socket (socket)
  "Close a socket without raising an error if something goes wrong"
  (handler-case
      (usocket:socket-close socket)
    (error (e)
      (logger "ignoring the error that happened while trying to close socket: ~a" e)))
  (logger "socket closed"))

(defun turn-into-pdf (message)
  (with-open-file (stream "output.tex" :direction :output :if-exists :overwrite)
    (format stream "~a" message))
  (trivial-shell:shell-command (concatenate 'string
					    "pdflatex -interaction=nonstopmode output.tex"))
  (file-string "output.pdf"))

(defun process-client-socket (client-socket)
  "Process client socket that got some activity"
  ;; NOTE: read-line blocks until end-of-line character is received
  ;; see http://mihai.bazon.net/blog/howto-multi-threaded-tcp-server-in-common-lisp
  ;; for read-byte-at-a-time solution
  (let ((message (read-line (usocket:socket-stream client-socket))))
    (logger "got a message: ~a" message)
    (send-text-to-socket (turn-into-pdf message) client-socket)))


(defun run-tcp-server (host port)
  "Run TCP server in a loop, listening to incoming connections.
  This is single-threaded version. Better approach would be to run
  process-client-socket in a separate thread every time there is activity
  on the client socket.
  All client sockets are kept in all-sockets list."
  (let* ((master-socket (usocket:socket-listen host port :backlog 256))
         (all-sockets `(,master-socket)))
    (loop
      (loop for sock in (usocket:wait-for-input all-sockets :ready-only t)
            do (if (eq sock master-socket)
                 ; new connection initiated
                 (let ((client-socket
                         (usocket:socket-accept master-socket :element-type 'character)))
                   (push client-socket all-sockets)
                   (logger "new socket initiated: ~a" client-socket))
                 ; client socket activity
                 (handler-case
                   (process-client-socket sock)
                   (t (e)
                      (logger "error during processing ~a" e)
                      (setf all-sockets (delete sock all-sockets))
                      (close-socket sock))))))))


(defun run-server-in-thread (host port)
  "Run TCP server in a separate thread"
  (let ((thread-name (format nil "tcp-server")))
    (logger "starting tcp server in a separate thread '~a'" thread-name)
    (sb-thread:make-thread
      (lambda () (run-tcp-server host port))
      :name thread-name)))


(defun main (&rest argv)
  (declare (ignorable argv))
  (sb-thread:join-thread 
    (run-server-in-thread "0.0.0.0" 8882))
:default nil)

