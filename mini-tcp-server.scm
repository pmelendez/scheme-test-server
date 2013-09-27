(require-extension tcp srfi-18)

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

(define delivery-messages 
	(lambda ()
		(letrec ((inner-loop
							 (lambda ()
								 (letrec 
									 ((local-send-message-to-all 
											(lambda (message socketlist)
												(if (not (null? socketlist))
													(begin
														(write message (cdar socketlist))
														(thread-sleep! 1)
														(local-send-message-to-all message (cdr socketlist))
														)
													#t)
												))
										; This is wrong, this need to be thought more carefully
										; We need to change the state of the message-queue.
										(local-handle-message 
											(lambda ()
												(if (not (null? message-queue))
													(begin 
														(local-send-message-to-all (car message-queue) socket-list)
														(set! message-queue (cdr message-queue))
														))
												(local-handle-message)
													)))
									 (local-handle-message )))))
			(thread-start! (make-thread inner-loop)))))
										 

(define read-messages 
  (lambda ()
    (letrec ((inner  (lambda ()
		       (letrec ((read-from (lambda (socketlist)
					     (thread-sleep! 1)
					     (if (not (null? socketlist))
					       (begin 
									 (if (char? (peek-char (caar socketlist)))
										 (let ((message (read (caar socketlist))))
											 (display message) (display "\n")
											 (set! message-queue (append message-queue (list message)))
											 (read-from (cdr socketlist)))
										 #f)
									 )
								 (read-from socket-list)))))
						 (read-from socket-list)))))
			(thread-start! (make-thread inner)))))

(define accept (lambda () (let ((thread (make-thread 
					  accept-handler)))
			    ;(thread-join! (thread-start! thread)))))
			    (thread-start! thread))))

(define debug-tick (lambda() (letrec ((deb (lambda () (thread-sleep! 1) (display message-queue) (deb))))
			       (thread-start! (make-thread deb)))))

(define main (lambda () 
	       (main)))

;(tcp-read-timeout 5)
(accept)
(delivery-messages)
(read-messages)
;(debug-tick)
(main)
