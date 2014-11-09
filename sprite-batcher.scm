(declare (unit sprite-batcher)
	 (uses batcher
	       primitives
	       shader
	       sprite))

(use srfi-1
     srfi-4
     matchable)

(define-record sprite-batcher
  batcher
  sprite-ids)

(define-record sprite-batch-id
  batch-id
  matrix
  sprite)


(define (sprite-batcher:create)
  (make-sprite-batcher 
   (batcher:create default-shader
		   *triangle-rect-mode*
		   4)
   (list)))

(define (sprite-batcher:push! sprite-batcher sprite matrix)
  (let* ((sprite-id (make-sprite-batch-id 
		     (batcher:push!
		      (sprite-batcher-batcher sprite-batcher)
		      ;; Vertex data
		      (matrix:vertex-data matrix)
		      ;; Coord data
		      (sprite:coord-data sprite))
		     matrix sprite)))
    (sprite-batcher-sprite-ids-set! 
     sprite-batcher 
     (cons sprite-id (sprite-batcher-sprite-ids sprite-batcher)))
    sprite-id))


(define (sprite-batcher:change! sprite-batcher sprite-batch-id matrix)
  (sprite-batch-id-matrix-set! sprite-batch-id matrix)
  (match-let ((($ sprite-batch-id batch-id matrix sprite) sprite-batch-id))
	     (batcher:change! (sprite-batcher-batcher sprite-batcher) 
			      batch-id
			      ;; Vertex data
			      vertex: (matrix:vertex-data matrix)
			      coord:  (sprite:coord-data sprite))))

(define (sprite-batcher:update! sprite-batcher)
  (for-each
   (lambda (sprite-id)
     (match-let ((($ sprite-batch-id batch-id matrix sprite)
		  sprite-id))
		;; TODO polls sprites too much.
		(when (sprite:animated? sprite)
		 (batcher:change! (sprite-batcher-batcher sprite-batcher)
				  batch-id
				  coord: (sprite:coord-data sprite)))))
   (sprite-batcher-sprite-ids sprite-batcher)))

(define (sprite-batcher:remove! sprite-batcher id)
  (batcher:remove! (sprite-batcher-batcher sprite-batcher) id)
  (sprite-batcher-sprite-ids-set! sprite-batcher
   (remove (lambda (x) (= (car x) id))
	   (sprite-batcher-sprite-ids sprite-batcher))))

(define (sprite-batcher:clear! sprite-batcher)
  (batcher:clear! (sprite-batcher-batcher sprite-batcher))
  (sprite-batcher-sprite-ids-set! sprite-batcher (list)))

(define (sprite-batcher:render sprite-batcher projection view)
  (when (not (null? (sprite-batcher-sprite-ids sprite-batcher)))
   (batcher:render (sprite-batcher-batcher sprite-batcher) 
		   projection view)))

;; %

(define (matrix:vertex-data matrix)
  (apply f32vector (flatten
    (map (lambda (vect)
	   (let ((r (vect*matrix vect matrix)))
	     (list (vect:x r)
		   (vect:y r))))
	 (polygon->vects (rect->polygon (rect:create 0 1 0 1)))))))
