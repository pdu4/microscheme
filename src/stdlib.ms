;; The Microscheme Standard Library
;; microscheme.org



;; Looping constructs

(define (forever f)
	(f)
	(forever f))

(define (vector-last vect)
	(- (vector-length vect) 1))

(define (for a z f)
	(if (<= a z)
		(begin
			(f a)
			(for (+ a 1) z f))))

;; Rich equivalence predicate

(define equal? #f)

(define (vector-equal-aux test? X Y N L)
	(if (= N L)
		#t
		(if (test? (vector-ref X N) (vector-ref Y N))
			(vector-equal-aux test? X Y (+ N 1) L)
			#f)))

(define equal? (lambda (X Y)
	(or
		(eq? X Y)
		(and 
			(pair? X)
			(pair? Y)
			(equal? (car X) (car Y))
			(equal? (cdr X) (cdr Y)))
		(and
			(vector? X)
			(vector? Y)
			(= (vector-length X) (vector-length Y))
			(vector-equal-aux equal? X Y 0 (vector-length X))))))

(define (all-vector-aux test X N L)
	(if (= N L)
		#t
		(if (test (vector-ref X N))
			(all-vector-aux test X (+ N 1) L)
			#f)))

(define (all-vector test vect)
	(all-vector-aux test vect 0 (vector-length vect)))

(define (string? str)
	(and
		(vector? str)
		(all-vector char? str)))

(define (list? x)
	(or (null? x)
		(and (pair? x) 
			(list? (cdr x)))))

(define (serial-init)
	; Set Baud Rate registers
	(asm "LDI GP1,	hi8(BAUD_9600)")
	(asm "STS	UBRR0H,	GP1				;; ..1H for mega 1")
	(asm "LDI	GP1,	lo8(BAUD_9600)")
	(asm "STS	UBRR0L,	GP1				;; ..1L for mega 1")

	; Set control registers
	(asm "CLR GP1")
	(asm "SBR GP1,	TXENm")
	(asm "SBR GP1,	RXENm")
	(asm "STS UCSR0B,	GP1				;; ..1B for mega 1"))


;; Digital Input/Output

(define arduino-ports)
(define arduino-pins)

(@if-model-mega
	(begin
		(set! arduino-ports	(vector #x2C	#x2C	#x2C	#x2C	#x32	#x2C	#x100	#x100
									#x100	#x100	#x23	#x23	#x23	#x23	#x109	#x109
									#x100	#x100	#x26	#x26	#x26	#x26	#x20	#x20	
									#x20	#x20	#x20	#x20	#x20	#x20	#x26	#x26
									#x26	#x26	#x26	#x26	#x26	#x26	#x26	#x32
									#x32	#x32	#x109	#x109	#x109	#x109	#x109	#x109
									#x109	#x109	#x23	#x23	#x23	#x23))
		(set! arduino-pins	(vector 1 2 16 32 32 8 8 16 32 64 16 32 64 128 2 1 2 1 8 4 2 1 1 2 4 
									8 16 32 64 128 128 64 32 16 8 4 2 1 128 4 2 1 128 64 32 16 8 
									4 2 1 8 4 2 1 1 2 4 8 16 32 64 128 1 2 4 8 16 32 64 128))))

(@if-model-uno
	(begin
		(set! arduino-ports	(vector #x29 #x29 #x29 #x29 #x29 #x29 #x29 #x29 #x23 #x23 #x23 #x23 #x23 #x23))
		(set! arduino-pins	(vector 1 2 4 8 16 32 64 128 1 2 4 8 16 32))))

(@if-model-leo
	(begin
		; D2 D3 D1 D0 D4 C6 D7 E6 B4 B5 B6 B7 D6 C7
        (set! arduino-ports	(vector #x29 #x29 #x29 #x29 #x29 #x26 #x29 #x2C #x23 #x23 #x23 #x23 #x29 #x26))
		(set! arduino-pins	(vector 4 8 2 1 16 64 128 64 16 32 64 128 64 128))))

(define (set-ddr apin val)
	(set-digital-state (+ 1 (vector-ref arduino-ports apin)) (vector-ref arduino-pins apin) val)
	apin)

(define (set-pin apin val)
	(set-digital-state (+ 2 (vector-ref arduino-ports apin)) (vector-ref arduino-pins apin) val)
	apin)

(define (output? apin)
	(digital-state (+ 1 (vector-ref arduino-ports apin)) (vector-ref arduino-pins apin)))
	
(define (high? apin)
	(digital-state (vector-ref arduino-ports apin) (vector-ref arduino-pins apin)))

(define (input p)	(set-ddr p #f))
(define (output p)	(set-ddr p #t))
(define (high p)	(set-pin p #t))
(define (low p)		(set-pin p #f))

(define (input? p)	(¬ (output? p)))
(define (low? p)	(¬ (high? p)))

(define (toggle p)	(set-pin p (low? p)))











;; List Processing Library
;; microscheme.org

(define (reverse-aux lst acc)
	(if (null? lst)
		acc
		(reverse-aux (cdr lst) (cons (car lst) acc))))

(define (reverse lst)
	(reverse-aux lst '()))

(define (append l m)
	(if (null? l) m
		(cons (car l)
			(append (cdr l) m))))

(define (map-aux proc lst acc)
	(if (null? lst)
		acc
		(map-aux proc (cdr lst) (cons (proc (car lst)) acc))))

(define (map proc lst)
	(reverse-aux (map-aux proc lst '()) '()))

(define (map-2-aux proc lst1 lst2 acc)
	(if (or (null? lst1) (null? lst2))
		acc
		(map-2-aux proc (cdr lst1) (cdr lst2) (cons (proc (car lst1) (car lst2)) acc))))

(define (map-2 proc lst1 lst2)
	(reverse-aux (map-2-aux proc lst1 lst2 '()) '()))

(define (zip x y)
	(map-2 cons x y))

(define (length-aux lst acc)
	(if (null? lst)
		acc
		(length-aux (cdr lst) (+ acc 1))))

(define (length lst)
	(length-aux lst 0))

(define (fold-right f z xs)
	(if (null? xs)
		z
		(f (car xs) (fold-right f z (cdr xs)))))

(define (fold f z xs)
	(if (null? xs)
		z
		(fold f (f z (car xs)) (cdr xs))))

(define (for-each proc lst)
	(if (null? lst)
		#t
		(begin
			(proc (car lst))
			(for-each proc (cdr lst)))))
		
(define (all test lst)
	(or (null? lst)
		(and (test (car lst)) 
			(all test (cdr lst)))))

(define (for-both p x)
	(p (car x))
	(p (cdr x)))







;; Vector Processing Library
;; microscheme.org

(define (fevstep proc vect i n)
	(if (< i n) 
		(begin
			(proc (vector-ref vect i))
			(fevstep proc vect (+ i 1) n))))

(define (for-each-vector proc vect)
	(fevstep proc vect 0 (vector-length vect)))

(define (fevrstep proc vect i)
	(proc (vector-ref vect i))
	(if (> i 0)
		(fevrstep proc vect (- i 1))))

(define (for-each-vector-reverse proc vect)
	(fevrstep proc vect (vector-last vect)))

(define (vlstep vect i n acc)
	(if (< i n) 
		(vlstep vect (+ i 1) n (cons (vector-ref vect i) acc))
		acc))

(define (make-writer vect index)
	(lambda (value)
		(vector-set! vect index value)
		(set! index (+ index 1))))

(define (vector-concat left right)
	(let ((destination (make-vector (+ (vector-length left) (vector-length right)))))
		(free!
			(let ((writer (make-writer destination 0)))
				(for-each-vector writer left)
				(for-each-vector writer right)
				destination))))

(define (vector-copy src dest src-start src-finish dest-start)
	(if (> src-start src-finish)
		dest
		(begin
			(vector-set! dest dest-start (vector-ref src src-start))
			(vector-copy src dest (+ src-start 1) src-finish (+ dest-start 1)))))

(define (sub-vector vect start finish)
	(vector-copy vect (make-vector (+ (- finish start) 1)) start finish 0))

(define (vector-first-step vect test start)
	(if (or (>= start (vector-length vect)) (test (vector-ref vect start))) 
		start
		(vector-first-step vect test (+ start 1))))

(define (vector-first vect test)
	(vector-first-step vect test 0))









(define (vector->list vect)
	(reverse (vlstep vect 0 (vector-length vect) '())))

(define (list->vector lst)
	(let ((vect (make-vector (length lst))))
		(free!
			(for-each (make-writer vect) lst))))