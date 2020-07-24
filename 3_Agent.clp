(defmodule AGENT (import MAIN ?ALL) (import ENV ?ALL) (export ?ALL))

; ________________ TEMPLATES ________________

(deftemplate cell_prob
	(slot x)
	(slot y)
	(slot val)
)

; ________________ FUNCTIONS ________________

(deffunction greater_than (?fact1 ?fact2)
	(> (fact-slot-value ?fact1 val) (fact-slot-value ?fact2 val))
)

(deffunction find_max (?template ?predicate)
	(bind ?max FALSE)
	(do-for-all-facts ((?f ?template)) TRUE
		(if (or (not ?max) (funcall ?predicate ?f ?max))
        then
        (bind ?max ?f)))
    (return ?max)
)

; ________________ RULES ________________

(defrule max_guesses
	(status (step ?s) (currently running))
	?mvs <- (moves (guesses ?ng &:(eq ?ng 0)))
=>
	(assert (exec (step ?s) (action solve)))
	(pop-focus)
)

(defrule calc_cell_values
	(status (step ?s) (currently running))
	(not (cell_prob (x ?x) (y ?y) (val ?val)))
=>
	(do-for-all-facts ((?kr k-per-row)) TRUE
		(do-for-all-facts((?kc k-per-col)) TRUE
			(if (not (any-factp ((?e exec)) (and (eq ?e:action fire) (eq ?e:x ?kr:row) (eq ?e:y ?kc:col))))
				then
				(assert (cell_prob (x ?kr:row) (y ?kc:col) (val (+ ?kc:num ?kr:num))))
			)
		)
	)
)


(defrule guess_best
	(status (step ?s) (currently running))
	(cell_prob (x ?x) (y ?y) (val ?val))
=>
	(bind ?max (find_max cell_prob greater_than))
	(assert (exec (step ?s) (action guess) (x (fact-slot-value ?max x)) (y (fact-slot-value ?max y))))
	(retract ?max)
	(pop-focus)
	
)

(defrule print-what-i-know-since-the-beginning
	(k-cell (x ?x) (y ?y) (content ?t) )
=>
	(printout t "I know that cell [" ?x ", " ?y "] contains " ?t "." crlf)
)

