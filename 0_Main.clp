(defmodule MAIN (export ?ALL))

; ________________ TEMPLATES ________________

(deftemplate exec
   (slot step)
   (slot action (allowed-values fire guess unguess solve))
   (slot x)
   (slot y)
)

(deftemplate status (slot step) (slot currently (allowed-values running stopped)) )

(deftemplate moves (slot fires) (slot guesses) )

(deftemplate statistics
	(slot num_fire_ok)
	(slot num_fire_ko)
	(slot num_guess_ok)
	(slot num_guess_ko)
	(slot num_safe)
	(slot num_sink)
)

; ________________ RULES ________________

(defrule go-on-env-first (declare (salience 30))
  ?f <- (first-pass-to-env)
=>

  (retract ?f)
  (focus ENV)
)


(defrule go-on-agent  (declare (salience 20))
   (maxduration ?d)
   (status (step ?s&:(< ?s ?d)) (currently running))

 =>

    (focus AGENT)
)



(defrule go-on-env  (declare (salience 30))
  ?f1<-	(status (step ?s))
  (exec (step ?s))

=>

  (focus ENV)

)

(defrule game-over
	(maxduration ?d)
	(status (step ?s&:(>= ?s ?d)) (currently running))
=>
	(assert (exec (step ?s) (action solve)))
	(focus ENV)
)

; ________________ INITIAL FACTS ________________

(deffacts initial-facts
	(maxduration 100)
	(status (step 0) (currently running))
  (statistics (num_fire_ok 0) (num_fire_ko 0) (num_guess_ok 0) (num_guess_ko 0) (num_safe 0) (num_sink 0))
	(first-pass-to-env)
	(moves (fires 5) (guesses 20) )
)

