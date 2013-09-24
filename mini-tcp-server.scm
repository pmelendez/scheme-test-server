(require-extension tcp posix srfi-18)

(define host "127.0.0.1")
(define port 14095)


(define listener (tcp-listen port))
(define socket-list '())
(define message-queue '())

(define accept-handler (lambda()
			 (begin
			   (define-values (in out) (tcp-accept listener))
			   (display "Accepted new connection\n")
			   (set! socket-list (append socket-list (cons (cons in out) '())))
			   (accept-handler)
			   )))

(define send-message (lambda ()
		       (letrec ((send-to (lambda(slist)
					   (begin
					     (display "Sending message to ") (display slist) (display "\n")
					     (if (not (null? slist)) (write-line "Hola\r\n" (cdar slist) ) #t)
					     (thread-sleep! 0.5)
					     (if (null? slist) (send-to socket-list) (send-to (cdr slist)))))))
			 (send-to socket-list))))

(define read-messages 
  (lambda ()
    (letrec ((inner  (lambda ()
		       (letrec ((read-from (lambda (socketlist)
					     (display "Entrando\n")
					     (thread-sleep! 0.5)
					     (if (not (null? socketlist))
					       (begin
						 (display "before read\n") 
						 (let ((message (read-line (caar socketlist))))
						   (display message) (display "\n")
						   (set! message-queue (append message-queue (list message)))
						   (read-from (cdr socketlist)))
						 )
					       (read-from socket-list)))))
			 (read-from socket-list)))))
      (thread-start! (make-thread inner)))))

(define accept (lambda () (let ((thread (make-thread 
					  accept-handler)))
			    ;(thread-join! (thread-start! thread)))))
			    (thread-start! thread))))

(define send-messages (lambda () (let ((thread (make-thread
						 send-message)))
				   (thread-start! thread))))

(define debug-tick (lambda() (letrec ((deb (lambda () (thread-sleep! 1) (display "tick") (deb))))
			       (thread-start! (make-thread deb)))))

(define main (lambda () 
	       (main)))

(accept)
(send-messages)
(read-messages)
(debug-tick)
(main)
