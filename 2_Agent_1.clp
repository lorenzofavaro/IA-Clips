(defmodule AGENT (import MAIN ?ALL) (import ENV ?ALL) (export ?ALL))

; ________________ TEMPLATES ________________

(deftemplate boats_to_find
	(slot boat_4)
	(slot boat_3)
	(slot boat_2)
	(slot boat_1)
)

(deftemplate cell_prob
	(slot x)
	(slot y)
	(slot val)
)

(deftemplate cell_to_see
	(slot x) (slot y) (slot action)
)

(deftemplate cell_considered
	(slot x) (slot y)
)

(deftemplate rule_in_progress
	(slot rule) (slot x) (slot y) (slot content))

; ________________ INITIAL FACTS ________________

(deffacts total_boats
	(boats_to_find (boat_4 1) (boat_3 2) (boat_2 3) (boat_1 4))
)

; ________________ FUNCTIONS ________________

(deffunction greater_than (?fact1 ?fact2)
	(> (fact-slot-value ?fact1 val) (fact-slot-value ?fact2 val))
)

(deffunction far_from_others (?x ?y)
	(if (any-factp ((?kcs cell_considered)) (or 
											(and (eq ?kcs:x (- ?x 1)) (eq ?kcs:y ?y))
											(and (eq ?kcs:x (+ ?x 1)) (eq ?kcs:y ?y))
											(and (eq ?kcs:x ?x) (eq ?kcs:y (- ?y 1)))
											(and (eq ?kcs:x ?x) (eq ?kcs:y (+ ?y 1)))
											(and (eq ?kcs:x (- ?x 1)) (eq ?kcs:y (+ ?y 1)))
											(and (eq ?kcs:x (+ ?x 1)) (eq ?kcs:y (- ?y 1)))
											(and (eq ?kcs:x (- ?x 1)) (eq ?kcs:y (- ?y 1)))
											(and (eq ?kcs:x (+ ?x 1)) (eq ?kcs:y (+ ?y 1))) ) )
		then
			return FALSE
		else
			return TRUE
	)

)

(deffunction find_max (?predicate)
	(bind ?max FALSE)
	(do-for-all-facts ((?f cell_prob)) (and (far_from_others ?f:x ?f:y) (not (any-factp ((?kcs cell_considered)) (and (eq ?kcs:x ?f:x) (eq ?kcs:y ?f:y)))))
		(if (or (not ?max) (funcall ?predicate ?f ?max))
        then
        (bind ?max ?f)))
    (return ?max)
)


(deffunction next_action (?action ?x ?y ?content ?diff)
	(if (eq ?content top)
		then
		(bind ?new_x (+ ?x ?diff))
		(if (< ?new_x 10)
		then
			(assert (cell_to_see (x ?new_x) (y ?y) (action ?action)))
		)
	)
	(if (eq ?content bot)
		then
		(bind ?new_x (- ?x ?diff))
		(if (>= ?new_x 0)
		then
			(assert (cell_to_see (x ?new_x) (y ?y) (action ?action)))
		)
	)

	(if (eq ?content left)
		then
		(bind ?new_y (+ ?y ?diff))
		(if (< ?new_y 10)
		then
			(assert (cell_to_see (x ?x) (y ?new_y) (action ?action)))
		)
	)

	(if (eq ?content right)
		then
		(bind ?new_y (- ?y ?diff))
		(if (>= ?new_y 0)
		then
			(assert (cell_to_see (x ?x) (y ?new_y) (action ?action)))
		)
	)
)


(deffunction max_prob_neighbour (?x ?y)
	(bind ?val1 0)
	(bind ?val2 0)
	(bind ?val3 0)
	(bind ?val4 0)
	(do-for-fact ((?kc k-per-col)) (eq ?kc:col ?y)
		(do-for-fact ((?kr1 k-per-row)) (eq ?kr1:row (- ?x 1))
			(if (>= ?kr1:row 0)
				then (bind ?val1 (+ ?kc:num ?kr1:num)))
		)

		(do-for-fact ((?kr2 k-per-row)) (eq ?kr2:row (+ ?x 1))
			(if (< ?kr2:row 10)
					then (bind ?val2 (+ ?kc:num ?kr2:num)))
		)
	)
	(do-for-fact ((?kr k-per-row)) (eq ?kr:row ?x)
		(do-for-fact ((?kc1 k-per-col)) (eq ?kc1:col (- ?y 1))
			(if (>= ?kc1:col 0)
				then (bind ?val3 (+ ?kr:num ?kc1:num)))
		)
		(do-for-fact ((?kc2 k-per-col)) (eq ?kc2:col (+ ?y 1))
			(if (< ?kc2:col 10)
				then (bind ?val4 (+ ?kr:num ?kc2:num)))
		)
	)
	(bind ?max_value (max ?val1 ?val2 ?val3 ?val4))
	(switch ?max_value
		(case ?val1 then return (create$ (- ?x 1) ?y))
		(case ?val2 then return (create$ (+ ?x 1) ?y))
		(case ?val3 then return (create$ ?x (- ?y 1)))
		(case ?val4 then return (create$ ?x (+ ?y 1)))
	)
)

; ________________ RULES ________________

(defrule out_of_fires
	(status (step ?s) (currently running))
	(moves (fires ?nf&:(eq ?nf 0)))
=>
	(assert (exec (step ?s) (action solve)))
	(pop-focus)
)


(defrule action_to_do (declare (salience 30))
	(status (step ?s) (currently running))
	?ts <- (cell_to_see (x ?x) (y ?y) (action ?action))
=>
	(retract ?ts)
	(assert (cell_considered (x ?x) (y ?y)))
	(assert (exec (step ?s) (action ?action) (x ?x) (y ?y)))
	(printout t "exec " ?action crlf)
	(pop-focus)
)

(defrule calc_cell_values (declare (salience -5))
	(status (step ?s) (currently running))
	(not (cell_prob (x ?x) (y ?y) (val ?val)))
=>
	(do-for-all-facts ((?kr k-per-row)) TRUE
		(do-for-all-facts((?kc k-per-col)) TRUE
			(if (not (any-factp ((?kcs cell_considered)) (and (eq ?kcs:x ?kr:row) (eq ?kcs:y ?kc:col))))
				then
				(assert (cell_prob (x ?kr:row) (y ?kc:col) (val (+ ?kc:num ?kr:num))))
			)
		)
	)
)


(defrule r43
	(status (step ?s) (currently running))
	(k-cell (x ?x) (y ?y) (content ?content&~sub&~middle))
	(not (cell_considered(x ?x) (y ?y)))
	?k <- (boats_to_find (boat_4 0) (boat_3 0) (boat_2 ?n2&:(neq ?n2 0)))
=>
	(assert (cell_considered (x ?x) (y ?y)))
	(next_action guess ?x ?y ?content 1)
	(modify ?k (boat_2 (- ?n2 1)))
)





(defrule r42
	(status (step ?s) (currently running))
	(k-cell (x ?x) (y ?y) (content ?content&~sub&~middle))
	(not (cell_considered (x ?x) (y ?y)))
	?k <- (boats_to_find (boat_4 0) (boat_3 ?n3&:(neq ?n3 0)) (boat_2 0))
=>
	(assert (cell_considered (x ?x) (y ?y)))
	(printout t ?x ?y " visto DA R42" crlf)
	(next_action guess ?x ?y ?content 1)
	(next_action guess ?x ?y ?content 2)
	(modify ?k (boat_3 (- ?n3 1)))
)





(defrule r4
	(status (step ?s) (currently running))
	(k-cell (x ?x) (y ?y) (content ?content&~sub&~middle))
	(not (cell_considered (x ?x) (y ?y)))
	?k <- (boats_to_find (boat_4 0) (boat_3 ?n3&:(neq ?n3 0)) (boat_2 ?n2&:(neq ?n2 0)))
=>
	(assert (cell_considered (x ?x) (y ?y)))
	(printout t ?x ?y " visto DA R4" crlf)
	(assert (rule_in_progress (rule r4) (x ?x) (y ?y) (content ?content)))

	(next_action fire ?x ?y ?content 2)
	(next_action guess ?x ?y ?content 1)
	
)

(defrule r4_aux
	(status (step ?s) (currently running))
	?r <- (rule_in_progress (rule r4) (x ?x) (y ?y) (content ?content))
	?k <- (boats_to_find (boat_4 ?n4) (boat_3 ?n3) (boat_2 ?n2))
=>
	(retract ?r)
	(printout t "trovata boat_2: " ?x " " ?y crlf)
	(modify ?k (boat_2 (- ?n2 1)))
)

(defrule r4_aux_2
	(status (step ?s) (currently running))
	?r <- (rule_in_progress (rule r4) (x ?x) (y ?y) (content ?content))
	(k-cell (x ?new_x) (y ?new_y) (content ?new_content))
	?k <- (boats_to_find (boat_4 ?n4) (boat_3 ?n3) (boat_2 ?n2))
=>
	(retract ?r)
	(printout t "trovata boat_3: " ?x " " ?y crlf)
	(modify ?k (boat_3 (- ?n3 1)))
)





(defrule r32
	(status (step ?s) (currently running))
	(k-cell (x ?x) (y ?y) (content ?content&~sub&~middle))
	(not (cell_considered (x ?x) (y ?y)))
	?k <- (boats_to_find (boat_4 ?n4&:(neq ?n4 0)) (boat_3 0) (boat_2 0))
=>
	(assert (cell_considered (x ?x) (y ?y)))
	(printout t ?x ?y " visto DA R32" crlf)
	(next_action guess ?x ?y ?content 1)
	(next_action guess ?x ?y ?content 2)
	(next_action guess ?x ?y ?content 3)
	(modify ?k (boat_4 0))
)





(defrule r3
	(status (step ?s) (currently running))
	(k-cell (x ?x) (y ?y) (content ?content&~sub&~middle))
	(not (cell_considered (x ?x) (y ?y)))
	?k <- (boats_to_find (boat_4 ?n4&:(neq ?n4 0)) (boat_3 0) (boat_2 ?n2&:(neq ?n2 0)))
=>
	(assert (cell_considered (x ?x) (y ?y)))
	(printout t ?x ?y " visto DA R3" crlf)
	(assert (rule_in_progress (rule r3) (x ?x) (y ?y) (content ?content)))

	(next_action fire ?x ?y ?content 1)
)

(defrule r3_aux
	(status (step ?s) (currently running))
	?r <- (rule_in_progress (rule r3) (x ?x) (y ?y) (content ?content))
	(k-cell (x ?new_x) (y ?new_y) (content ?new_content))
	?k <- (boats_to_find (boat_4 ?n4) (boat_3 ?n3) (boat_2 ?n2))
=>
	(retract ?r)
	(if (eq ?new_content middle)
		then
		(next_action guess ?x ?y ?content 2)
		(next_action guess ?x ?y ?content 3)
		(modify ?k (boat_4 (- ?n4 1)))
		else
		(modify ?k (boat_2 (- ?n2 1)))
	)
)





(defrule r2
	(status (step ?s) (currently running))
	(k-cell (x ?x) (y ?y) (content ?content&~sub&~middle))
	(not (cell_considered (x ?x) (y ?y)))
	?k <- (boats_to_find (boat_4 ?n4&:(neq ?n4 0)) (boat_3 ?n3&:(neq ?n3 0)) (boat_2 0))
=>
	(assert (cell_considered (x ?x) (y ?y)))
	(printout t ?x ?y " visto DA R2" crlf)
	(assert (rule_in_progress (rule r2) (x ?x) (y ?y) (content ?content)))

	(next_action fire ?x ?y ?content 2)
	(next_action guess ?x ?y ?content 1)
)

(defrule r2_aux
	(status (step ?s) (currently running))
	?r <- (rule_in_progress (rule r2) (x ?x) (y ?y) (content ?content))
	(k-cell (x ?new_x) (y ?new_y) (content ?new_content))
	?k <- (boats_to_find (boat_4 ?n4) (boat_3 ?n3) (boat_2 ?n2))
=>
	(retract ?r)
	(if (eq ?new_content middle)
		then (next_action guess ?x ?y ?content 3) (modify ?k (boat_4 1))
		else (modify ?k (boat_3 (- ?n3 1)))
	)
)





(defrule r
	(status (step ?s) (currently running))
	(k-cell (x ?x) (y ?y) (content ?content&~sub&~middle))
	(not (cell_considered (x ?x) (y ?y)))
=>
	(assert (cell_considered (x ?x) (y ?y)))
	(printout t ?x ?y " visto DA R" crlf)
	(assert (rule_in_progress (rule r) (x ?x) (y ?y) (content ?content)))

	(next_action fire ?x ?y ?content 2)
	(next_action guess ?x ?y ?content 1)
)

(defrule r_water
	(status (step ?s) (currently running))
	?r <- (rule_in_progress (rule r) (x ?x) (y ?y) (content ?content))
	?k <- (boats_to_find (boat_4 ?n4) (boat_3 ?n3) (boat_2 ?n2))
=>
	(modify ?k (boat_2 (- ?n2 1)))
	(retract ?r)
)

(defrule r_aux (declare (salience 5))
	(status (step ?s) (currently running))
	?r <- (rule_in_progress (rule r) (x ?x) (y ?y) (content ?content))
	(k-cell (x ?new_x) (y ?new_y) (content ?new_content))
	?k <- (boats_to_find (boat_4 ?n4) (boat_3 ?n3) (boat_2 ?n2))
=>
	(retract ?r)

	(if (eq ?new_content middle)
		then
		(next_action guess ?x ?y ?content 3)
		(modify ?k (boat_4 0))
		else
		(modify ?k (boat_3 (- ?n3 1)))
	)
)





(defrule r_middle
	(status (step ?s) (currently running))
	(k-cell (x ?x) (y ?y) (content ?content&middle))
	(not (cell_considered (x ?x) (y ?y)))
=>
	(assert (cell_considered (x ?x) (y ?y)))
	(printout t ?x ?y " visto DA R_MIDDLE" crlf)
	(bind ?cell (max_prob_neighbour ?x ?y))
	(bind ?new_x (nth$ 1 ?cell)) (bind ?new_y (nth$ 2 ?cell))

	(assert (cell_to_see (x ?new_x) (y ?new_y) (action fire)))
	(assert (rule_in_progress (rule r_middle) (x ?x) (y ?y) (content ?content)))
)

(defrule r_middle_water
	(status (step ?s) (currently running))
	?r <- (rule_in_progress (rule r_middle) (x ?x) (y ?y) (content ?content))
=>
	(retract ?r)
)

(defrule r_middle_aux (declare (salience 5))
	(status (step ?s) (currently running))
	?r <- (rule_in_progress (rule r_middle) (x ?x) (y ?y) (content ?content))
	(k-cell (x ?new_x) (y ?new_y) (content ?new_content))
	?k <- (boats_to_find (boat_4 ?n4) (boat_3 ?n3) (boat_2 ?n2))
=>
	(retract ?r)
	(if (neq ?new_content middle)
	then
		(next_action guess ?x ?y ?new_content 1)
		(if (or (eq ?n3 0) (and (neq ?n4 0) (>= ?n4 ?n3) ))
			then (next_action guess ?x ?y ?new_content 2)
			(modify ?k (boat_4 0))
		else
			(modify ?k (boat_3 (- ?n3 1)))
		)
	else
		(assert (cell_to_see (x (- ?x (- ?new_x ?x))) (y (- ?y (- ?new_y ?y))) (action guess)))
		(assert (cell_to_see (x (+ ?new_x (- ?new_x ?x))) (y (+ ?new_y (- ?new_y ?y))) (action guess)))
		(modify ?k (boat_4 0))
	)
)

(defrule unknown (declare (salience -5))
	(status (step ?s) (currently running))
	(cell_prob (x ?x) (y ?y) (val ?val))
	(moves (fires ?nf))
=>
	(bind ?max (find_max greater_than))
	(assert (exec (step ?s) (action fire) (x (fact-slot-value ?max x)) (y (fact-slot-value ?max y))))

	(retract ?max)
	(pop-focus)
)


(defrule print-what-i-know-since-the-beginning
	(k-cell (x ?x) (y ?y) (content ?t) )
=>
	(printout t "I know that cell [" ?x ", " ?y "] contains " ?t "." crlf)
)

