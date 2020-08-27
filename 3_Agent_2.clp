(defmodule AGENT (import MAIN ?ALL) (import ENV ?ALL) (export ?ALL))


; ________________ TEMPLATES ________________

(deftemplate boats_to_find
	(slot boat_4)
	(slot boat_3)
	(slot boat_2)
	(slot boat_1)
)


(deftemplate cell_to_see
	(slot x) (slot y) (slot action)
)

(deftemplate cell_considered
	(slot x) (slot y)
)

; Template per l'aggiornamento delle celle oggetto di azione
(deftemplate cell_updated
	(slot x) (slot y)
)

; Template per l'aggiornamento delle celle a cui è stata aggiunta la water intorno
(deftemplate cell_watered
	(slot x) (slot y)
)

; Template per il riconoscimento della nave trovata, e per il decremento del numero di boat da trovare
(deftemplate boat_decremented
    (slot x) (slot y)
)

; Template per l'azione di base dei last, ossia l'assert della cella a fianco
(deftemplate action_base_done
	(slot x) (slot y)
)

; Template per i bordi del campo da gioco
(deftemplate border
    (slot x) (slot y)
)

; Template che viene asserito ad ogni fire, per il controllo in caso di water
(deftemplate fired
    (slot x) (slot y)
)

(deftemplate guessed
    (slot x) (slot y)
)



; ________________ INITIAL FACTS ________________

(deffacts total_boats
	(boats_to_find (boat_4 1) (boat_3 2) (boat_2 3) (boat_1 4))
)

(deffacts game_borders
    (border (x -1) (y 0)) (border (x 10) (y 0)) (border (x 0) (y -1)) (border (x 0) (y 10))
    (border (x -1) (y 1)) (border (x 10) (y 1)) (border (x 1) (y -1)) (border (x 1) (y 10))
    (border (x -1) (y 2)) (border (x 10) (y 2)) (border (x 2) (y -1)) (border (x 2) (y 10))
    (border (x -1) (y 3)) (border (x 10) (y 3)) (border (x 3) (y -1)) (border (x 3) (y 10))
    (border (x -1) (y 4)) (border (x 10) (y 4)) (border (x 4) (y -1)) (border (x 4) (y 10))
    (border (x -1) (y 5)) (border (x 10) (y 5)) (border (x 5) (y -1)) (border (x 5) (y 10))
    (border (x -1) (y 6)) (border (x 10) (y 6)) (border (x 6) (y -1)) (border (x 6) (y 10))
    (border (x -1) (y 7)) (border (x 10) (y 7)) (border (x 7) (y -1)) (border (x 7) (y 10))
    (border (x -1) (y 8)) (border (x 10) (y 8)) (border (x 8) (y -1)) (border (x 8) (y 10))
    (border (x -1) (y 9)) (border (x 10) (y 9)) (border (x 9) (y -1)) (border (x 9) (y 10))
)

; ________________ FUNCTIONS ________________

; Verifica se una determinata cella esista all'interno del campo da gioco 10x10
(deffunction is_valid_cell (?x ?y)
    (if (and (>= ?x 0) (>= ?y 0) (<= ?x 9) (<= ?y 9))
        then
            return TRUE
        else
            return FALSE
    )
)

(deffunction is_kcell (?x ?y ?supposed_content)
    (if (any-factp ((?kc k-cell)) (and (eq ?kc:x ?x) (eq ?kc:y ?y) (eq ?kc:content ?supposed_content))) then
        return TRUE
    else
        return FALSE
    )
)

; Verifica se una determinata nave corrispondente ad una cella sia già stata decrementata dal totale delle boat_n
(deffunction is_boat_decremented (?x ?y)
    (if (any-factp ((?bd boat_decremented)) (and (eq ?bd:x ?x) (eq ?bd:y ?y))) then
        return TRUE
    else
        return FALSE
    )
)

; Verifica se una cella è una boat o parte di una boat
(deffunction is_cell_boat (?x ?y)
    (if (any-factp ((?cu cell_updated)) (and (eq ?cu:x ?x) (eq ?cu:y ?y))) then
        return TRUE
    else
        return FALSE
    )
)

; Verifica se una cella è water
(deffunction is_cell_water (?x ?y)
    (if (any-factp ((?kc k-cell)) (and (eq ?kc:x ?x) (eq ?kc:y ?y) (eq ?kc:content water) )) then
        return TRUE
    else
        return FALSE
    )
)

; Verifica se una cella è water o non fa parte del campo di gioco
(deffunction is_cell_water_or_inexistent (?x ?y)
    (if (or (not (is_valid_cell ?x ?y)) (is_cell_water ?x ?y)) then
        return TRUE
    else
        return FALSE
    )
)

; Verifica se una cella è disponibile
(deffunction is_cell_available (?x ?y)
    (if (and (is_valid_cell ?x ?y) (not (or (is_cell_water ?x ?y) (is_cell_boat ?x ?y)))) then
        return TRUE
    else
        return FALSE
    )
)


; Data una cella, se non esiste una k-cell contenente water la asserisce
(deffunction assert_water (?x ?y)

    (if (is_cell_available ?x ?y) then
        (assert (k-cell (x ?x) (y ?y) (content water)))
    )
)

; Data una cella contenente una boat (tranne middle), asserisce tutte le celle circostanti come water
(deffunction water_around (?x ?y ?content)
    (assert (cell_watered (x ?x) (y ?y)))
    (if (neq ?content none) then
        (printout t "-F- water_around " ?content ": " ?x " " ?y crlf)
    )
    (assert_water (- ?x 1) (- ?y 1))
    (assert_water (- ?x 1) (+ ?y 1))
    (assert_water (+ ?x 1) (- ?y 1))
    (assert_water (+ ?x 1) (+ ?y 1))

    (switch ?content
        (case top then
            (assert_water ?x (- ?y 1))
            (assert_water ?x (+ ?y 1))
            (assert_water (- ?x 1) ?y)
            (assert_water (+ ?x 2) (- ?y 1))
            (assert_water (+ ?x 2) (+ ?y 1)))
        (case bot then
            (assert_water ?x (- ?y 1))
            (assert_water ?x (+ ?y 1))
            (assert_water (+ ?x 1) ?y)
            (assert_water (- ?x 2) (- ?y 1))
            (assert_water (- ?x 2) (+ ?y 1)))
        (case left then
            (assert_water ?x (- ?y 1))
            (assert_water (- ?x 1) ?y)
            (assert_water (+ ?x 1) ?y)
            (assert_water (- ?x 1) (+ ?y 2))
            (assert_water (+ ?x 1) (+ ?y 2)))
        (case right then
            (assert_water ?x (+ ?y 1))
            (assert_water (- ?x 1) ?y)
            (assert_water (+ ?x 1) ?y)
            (assert_water (- ?x 1) (- ?y 2))
            (assert_water (+ ?x 1) (- ?y 2)))
        (case sub then
            (assert_water (- ?x 1) ?y)
            (assert_water ?x (- ?y 1))
            (assert_water ?x (+ ?y 1))
            (assert_water (+ ?x 1) ?y))
        (default none)
    )

)


(deffunction water_around_unknown (?x ?y ?orientation)
    (assert (cell_watered (x ?x) (y ?y)))
    (printout t "-F- water_around_unknown: " ?x " " ?y " - orientation: " ?orientation crlf)

    (assert_water (+ ?x 1) (+ ?y 1))
    (assert_water (+ ?x 1) (- ?y 1))
    (assert_water (- ?x 1) (- ?y 1))
    (assert_water (- ?x 1) (+ ?y 1))

    (switch ?orientation
        (case vertical then
            (assert_water ?x (- ?y 1))
            (assert_water ?x (+ ?y 1)))
        
        (case horizontal then
            (assert_water (- ?x 1) ?y)
            (assert_water (+ ?x 1) ?y)
        )

    )

)

; Asserisce la prossima action e circonda la cella di water (LAST)
(deffunction next_action (?action ?x ?y ?content)

    (if (is_cell_available ?x ?y) then
        (assert (cell_to_see (x ?x) (y ?y) (action ?action)))

        (if (eq ?action guess) then
            (water_around ?x ?y ?content)
        )
    )
)


; Asserisce la prossima action e circonda la cella di water (unknown)
(deffunction next_action_unknown (?action ?x ?y ?orientation)

    (if (is_cell_available ?x ?y) then
        (assert (cell_to_see (x ?x) (y ?y) (action ?action)))

        (if (eq ?action guess) then
            (water_around_unknown ?x ?y ?orientation)
        )
    )
)


; Fa la guess delle celle disponibili di una row/col
(deffunction guess_rest (?type ?value ?n_available)
    (bind ?counter 0)
    (switch ?type

        (case row then
            (loop-for-count (?y 0 10) do

                ; Se cella disponibile
                (if (is_cell_available ?value ?y) then
                    
                    ; Conteggio i pezzi di boat consecutivi trovati
                    (bind ?counter (+ ?counter 1))
                else
                    (if (eq ?counter 1) then
                        (if (and (is_cell_water_or_inexistent (- ?value 1) (- ?y 1)) (is_cell_water_or_inexistent (+ ?value 1) (- ?y 1))) then
                            ; Sub
                            (next_action guess ?value (- ?y 1) sub)
                        else
                            ; Potrebbe essere un pezzo di un'altra nave
                            (next_action_unknown guess ?value (- ?y 1) vertical)
                        )
                        (bind ?counter 0)
                    else
                        (while (> ?counter 0)
                            (next_action_unknown guess ?value (- ?y ?counter) horizontal)
                            (bind ?counter (- ?counter 1))
                        )
                    )
                )
            )
        )

        (case col then
            (loop-for-count (?x 0 10) do

                ; Se cella disponibile
                (if (is_cell_available ?x ?value) then
                    
                    ; Conteggio i pezzi di boat consecutivi trovati
                    (bind ?counter (+ ?counter 1))
                else
                    (if (eq ?counter 1) then
                        (if (and (is_cell_water_or_inexistent (- ?x 1) (- ?value 1)) (is_cell_water_or_inexistent (- ?x 1) (+ ?value 1))) then
                            ; Sub
                            (next_action guess (- ?x 1) ?value sub)
                        else
                            ; Potrebbe essere un pezzo di un'altra nave
                            (next_action_unknown guess (- ?x 1) ?value horizontal)
                        )
                        (bind ?counter 0)
                    else
                        (while (> ?counter 0)
                            (next_action_unknown guess (- ?x ?counter) ?value vertical)
                            (bind ?counter (- ?counter 1))
                        )
                    )
                )
            )
        )
    )
)

(deffunction kp_sum (?x ?y)
    (do-for-fact ((?kr k-per-row)) (eq ?kr:row ?x)
        (do-for-fact ((?kc k-per-col)) (eq ?kc:col ?y)
            (bind ?tot (+ ?kr:num ?kc:num))
            (return ?tot)
        )
    )

)

(deffunction most_prob_cell ()
    (bind ?max FALSE)
    (bind ?max_x FALSE)
    (bind ?max_y FALSE)
    (loop-for-count (?x 0 9)
        (loop-for-count (?y 0 9)
            (if (and 
                    (is_cell_available ?x ?y)
                    (not (is_cell_boat (- ?x 1) (- ?y 1)))
                    (not (is_cell_boat (- ?x 1) (+ ?y 1)))
                    (not (is_cell_boat (+ ?x 1) (- ?y 1)))
                    (not (is_cell_boat (+ ?x 1) (+ ?y 1)))
                    (not (is_boat_decremented (- ?x 1) ?y))
                    (not (is_boat_decremented (+ ?x 1) ?y))
                    (not (is_boat_decremented ?x (- ?y 1)))
                    (not (is_boat_decremented ?x (+ ?y 1)))
                
                ) then

                (bind ?sum (kp_sum ?x ?y))
                ; Asseconda le guess fatte inizialmente
                ; (if (or (is_cell_boat (- ?x 1) ?y) (is_cell_boat (+ ?x 1) ?y) (is_cell_boat ?x (- ?y 1)) (is_cell_boat ?x (+ ?y 1))) then
                ;     (bind ?sum (+ ?sum 1))
                ; )
                (if (or (not ?max) (> ?sum ?max)) then
                    (bind ?max ?sum)
                    (bind ?max_x ?x)
                    (bind ?max_y ?y)
                )
            )
        )
    )
    return (create$ ?max_x ?max_y)
)


; ________________ RULES ________________


; Regola che lancia le guesses e le fires e rilascia il focus
(defrule action_to_do (declare (salience 50))
	(status (step ?s) (currently running))
	?ts <- (cell_to_see (x ?x) (y ?y) (action ?action))
    (not (cell_considered (x ?x) (y ?y)))
=>
	(retract ?ts)
	(assert (cell_considered (x ?x) (y ?y)))
    (if (eq ?action guess) then
        (assert (guessed (x ?x) (y ?y)))
    else
        (assert (fired (x ?x) (y ?y)))
    )
	(assert (exec (step ?s) (action ?action) (x ?x) (y ?y)))
	(printout t "exec " ?action ": " ?x " " ?y crlf)
	(pop-focus)
)

; REASONING AND INFERENCE (CERTAINTY)

(defrule considered_if_decremented (declare (salience 45))
    (status (step ?s) (currently running))
    (boat_decremented (x ?x) (y ?y))
    (not (cell_considered (x ?x) (y ?y)))
=>
    (assert (cell_considered (x ?x) (y ?y)))
)

; Per ogni k-cell decrementa il k-per-row e k-per-col
(defrule update_kcp (declare (salience 40))
    (status (step ?s) (currently running))
    (or
        (k-cell (x ?x) (y ?y) (content ~water))
        (guessed (x ?x) (y ?y))
    )
    ?kpr <- (k-per-row (row ?x) (num ?n1&:(> ?n1 0)))
    ?kpc <- (k-per-col (col ?y) (num ?n2&:(> ?n2 0)))
    (not (cell_updated (x ?x) (y ?y)))
=>
    (printout t "-R- update_kcp: " ?x " " ?y crlf)
    (assert (cell_updated (x ?x) (y ?y)))
    (modify ?kpr (num (- ?n1 1)))
    (modify ?kpc (num (- ?n2 1)))
)

; In caso di k-cell LAST e SUB asserisce le celle circostanti come water
(defrule water_cell (declare (salience 35))
	(status (step ?s) (currently running))
	(k-cell (x ?x) (y ?y) (content ?content&~middle&~water))
    (not (cell_watered (x ?x) (y ?y)))
=>
    (printout t "-R- water_cell: " ?x " " ?y crlf)
    (water_around ?x ?y ?content)
)

(defrule r_last_action_base (declare (salience 30))
    (status (step ?s) (currently running))
    (k-cell (x ?x) (y ?y) (content ?content&~middle&~water&~sub))
    (not (action_base_done (x ?x) (y ?y)))
=>
    (switch ?content
        (case top then
            (next_action_unknown guess (+ ?x 1) ?y vertical))
        (case bot then
            (next_action_unknown guess (- ?x 1) ?y vertical))
        (case left then
            (next_action_unknown guess ?x (+ ?y 1) horizontal))
        (case right then
            (next_action_unknown guess ?x (- ?y 1) horizontal))
    )
    (assert (action_base_done (x ?x) (y ?y)))
)


; In caso si trovi una k-cell MIDDLE ai bordi sopra/sotto della mappa
(defrule r_middle_border_horizontal (declare (salience 30))
    (status (step ?s) (currently running))
	(k-cell (x ?x&:(or (eq ?x 0) (eq ?x 9))) (y ?y) (content middle))
    (or
        (not (cell_updated (x ?x) (y ?y1&:(eq ?y1 (- ?y 1)))))
        (not (cell_updated (x ?x) (y ?y1&:(eq ?y1 (+ ?y 1)))))
    ) 
=>
    (printout t "r_middle_border_horizontal attivato" crlf)
    (assert (cell_considered (x ?x) (y ?y)))
    (next_action_unknown guess ?x (- ?y 1) horizontal)
    (next_action_unknown guess ?x (+ ?y 1) horizontal)
)

; In caso si trovi una k-cell MIDDLE ai bordi a destra/sinistra della mappa
(defrule r_middle_border_vertical (declare (salience 30))
    (status (step ?s) (currently running))
	(k-cell (x ?x) (y ?y&:(or (eq ?y 0) (eq ?y 9))) (content middle))
    (or
        (not (cell_updated (x ?x1&:(eq ?x1 (- ?x 1))) (y ?y)))
        (not (cell_updated (x ?x1&:(eq ?x1 (+ ?x 1))) (y ?y)))
    )
=>
    (printout t "r_middle_border_vertical attivato" crlf)
    (assert (cell_considered (x ?x) (y ?y)))
    (next_action_unknown guess (- ?x 1) ?y vertical)
    (next_action_unknown guess (+ ?x 1) ?y vertical)
)

; In caso trovi una cella water sopra/sotto una MIDDLE, inferisce la direzione della boat
(defrule r_middle_water_horizontal (declare (salience 30))
    (status (step ?s) (currently running))
	(k-cell (x ?x) (y ?y) (content middle))
    (k-cell (x ?x1&:(or (eq ?x1 (- ?x 1)) (eq ?x1 (+ ?x 1)) )) (y ?y) (content water))
    (or
        (not (cell_updated (x ?x) (y ?y1&:(eq ?y1 (- ?y 1)))))
        (not (cell_updated (x ?x) (y ?y1&:(eq ?y1 (+ ?y 1)))))
    )
=>
    (assert (cell_considered (x ?x) (y ?y)))
    (printout t "trovato 1/2 water sopra/sotto un middle" crlf)
    (next_action_unknown guess ?x (- ?y 1) horizontal)
    (next_action_unknown guess ?x (+ ?y 1) horizontal)
)

; In caso trovi una cella water a destra/sinistra una MIDDLE, inferisce la direzione della boat
(defrule r_middle_water_vertical (declare (salience 30))
    (status (step ?s) (currently running))
	(k-cell (x ?x) (y ?y) (content middle))
    (k-cell (x ?x) (y ?y1&:(eq ?y1 (- ?y 1))) (content water))
    (or
        (not (cell_updated (x ?x1&:(eq ?x1 (- ?x 1))) (y ?y)))
        (not (cell_updated (x ?x1&:(eq ?x1 (+ ?x 1))) (y ?y)))
    )
=>
    (assert (cell_considered (x ?x) (y ?y)))
    (printout t "trovato 1/2 water a destra/sinistra un middle" crlf)
    (next_action_unknown guess (- ?x 1) ?y vertical)
    (next_action_unknown guess (+ ?x 1) ?y vertical)
)


; Regola in azione quando una k-per-row è 0, asserisce che le celle non conosciute di quella row sono water
(defrule zero_kpr (declare (salience 25))
    (status (step ?s) (currently running))
    ?k <- (k-per-row (row ?row) (num 0))
=>
    (printout t "-F- water_row: " ?row crlf)
    (modify ?k (num -1))
    (loop-for-count (?y 0 9) do
        (assert_water ?row ?y)
    )
)

; Regola in azione quando una k-per-col è 0, asserisce che le celle non conosciute di quella col sono water
(defrule zero_kpc (declare (salience 25))
    (status (step ?s) (currently running))
    ?k <- (k-per-col (col ?col) (num 0))
=>
    (printout t "-F- water_col: " ?col crlf)
    (modify ?k (num -1))
    (loop-for-count (?x 0 9) do
        (assert_water ?x ?col)
    )
)

; Regola in azione quando in una row, il numero celle disponibili (non contengono water o boat) è uguale al valore di k-per-row
(defrule rest_available_row (declare (salience 20))
    (status (step ?s) (currently running))
    (k-per-row (row ?row) (num ?num&:(> ?num 0)))
    ;(test (eq ?num (- 10 (+ (length$ (find-all-facts ((?kc k-cell)) (eq ?kc:x ?row))) (length$ (find-all-facts ((?gu guessed)) (eq ?gu:x ?row)))))))
=>
    (bind ?tot (+ (length$ (find-all-facts ((?kc k-cell)) (eq ?kc:x ?row))) (length$ (find-all-facts ((?gu guessed)) (eq ?gu:x ?row)))))
    (if (eq ?num (- 10 ?tot)) then
        (printout t "-R- rest_available_row " ?row": " ?num "=" (- 10 ?tot) crlf)
        (guess_rest row ?row ?num)
    )
)

; Regola in azione quando in una col, il numero celle disponibili (non contengono water o boat) è uguale al valore di k-per-col
(defrule rest_available_col (declare (salience 20))
    (status (step ?s) (currently running))
    (k-per-col (col ?col) (num ?num&:(> ?num 0)))
    ;(test (eq ?num (- 10 (+ (length$ (find-all-facts ((?kc k-cell)) (eq ?kc:y ?col))) (length$ (find-all-facts ((?gu guessed)) (eq ?gu:y ?col)))))))
=>
    (bind ?tot (+ (length$ (find-all-facts ((?kc k-cell)) (eq ?kc:y ?col))) (length$ (find-all-facts ((?gu guessed)) (eq ?gu:y ?col)))))
    (if (eq ?num (- 10 ?tot)) then
        (printout t "-R- rest_available_col " ?col": " ?num "=" (- 10 ?tot) crlf)
        (guess_rest col ?col ?num)
    )
)


; Se c'è una fila orizzontale di boat o presunte boat lunga 4, la riconosce come nave intera e decrementa boat_4
(defrule boat_is_long_4_hor (declare (salience 16))
    (status (step ?s) (currently running))
    ?btf <- (boats_to_find (boat_4 1))

    (cell_updated (x ?x) (y ?y))
    (cell_updated (x ?x) (y ?y1&:(eq ?y1 (+ ?y 1))))
    (cell_updated (x ?x) (y ?y2&:(eq ?y2 (+ ?y 2))))
    (cell_updated (x ?x) (y ?y3&:(eq ?y3 (+ ?y 3))))

=>
    (printout t "boat_is_long_4_hor" crlf)

    (modify ?btf (boat_4 0))
    (assert (boat_decremented (x ?x) (y ?y)))
    (assert (boat_decremented (x ?x) (y ?y1)))
    (assert (boat_decremented (x ?x) (y ?y2)))
    (assert (boat_decremented (x ?x) (y ?y3)))

)

; Se c'è una fila verticale di boat o presunte boat lunga 4, la riconosce come nave intera e decrementa boat_4
(defrule boat_is_long_4_ver (declare (salience 16))
    (status (step ?s) (currently running))
    ?btf <- (boats_to_find (boat_4 1))

    (cell_updated (x ?x) (y ?y))
    (cell_updated (x ?x1&:(eq ?x1 (+ ?x 1))) (y ?y))
    (cell_updated (x ?x2&:(eq ?x2 (+ ?x 2))) (y ?y))
    (cell_updated (x ?x3&:(eq ?x3 (+ ?x 3))) (y ?y))

=>
    (printout t "boat_is_long_4_ver" crlf)

    (modify ?btf (boat_4 0))
    (assert (boat_decremented (x ?x) (y ?y)))
    (assert (boat_decremented (x ?x1) (y ?y)))
    (assert (boat_decremented (x ?x2) (y ?y)))
    (assert (boat_decremented (x ?x3) (y ?y)))
)

(defrule sub_kcell (declare (salience 15))
    (status (step ?s) (currently running))
    ?btf <- (boats_to_find (boat_1 ?n1))

	(k-cell (x ?x) (y ?y) (content sub))
    (not (boat_decremented (x ?x) (y ?y)))
=>
    (printout t "sub_kcell: " ?x " " ?y crlf)

    (modify ?btf (boat_1 (- ?n1 1)))
    (assert (boat_decremented (x ?x) (y ?y)))
)

(defrule sub_found (declare (salience 15))
    (status (step ?s) (currently running))
    ?btf <- (boats_to_find (boat_1 ?n1))

    (guessed (x ?x) (y ?y))
    (not (boat_decremented (x ?x) (y ?y)))
    (or
        (k-cell (x ?x) (y ?y1&:(eq ?y1 (- ?y 1))) (content water))
        (border (x ?x) (y ?y1&:(eq ?y1 (- ?y 1))))
    )
    (or
        (k-cell (x ?x) (y ?y2&:(eq ?y2 (+ ?y 1))) (content water))
        (border (x ?x) (y ?y2&:(eq ?y2 (+ ?y 1))))
    )
    (or
        (k-cell (x ?x1&:(eq ?x1 (- ?x 1))) (y ?y) (content water))
        (border (x ?x1&:(eq ?x1 (- ?x 1))) (y ?y))
    )
    (or
        (k-cell (x ?x2&:(eq ?x2 (+ ?x 1))) (y ?y) (content water))
        (border (x ?x2&:(eq ?x2 (+ ?x 1))) (y ?y))
    )
=>
    (printout t "sub_found: " ?x " " ?y crlf)

    (modify ?btf (boat_1 (- ?n1 1)))
    (assert (boat_decremented (x ?x) (y ?y)))
)


; Se c'è una fila orizzontale di boat o presunte boat lunga 3, ed è circondata da water, la riconosce come nave intera e decrementa boat_3
(defrule boat_is_limited_3_hor (declare (salience 15))
    (status (step ?s) (currently running))
    ?btf <- (boats_to_find (boat_3 ?n3&~0))

    (cell_updated (x ?x) (y ?y))
    (not (boat_decremented (x ?x) (y ?y)))

    (cell_updated (x ?x) (y ?y1&:(eq ?y1 (+ ?y 1))))
    (cell_updated (x ?x) (y ?y2&:(eq ?y2 (+ ?y 2))))

    (or
        (k-cell (x ?x) (y ?y3&:(eq ?y3 (- ?y 1))) (content water))
        (border (x ?x) (y ?y3&:(eq ?y3 (- ?y 1)))))
    (or
        (k-cell (x ?x) (y ?y4&:(eq ?y4 (+ ?y 3))) (content water))
        (border (x ?x) (y ?y4&:(eq ?y4 (+ ?y 3)))))
=>
    (printout t "boat_is_limited_3_hor" crlf)

    (modify ?btf (boat_3 (- ?n3 1)))
    (assert (boat_decremented (x ?x) (y ?y)))
    (assert (boat_decremented (x ?x) (y ?y1)))
    (assert (boat_decremented (x ?x) (y ?y2)))
)

; Se c'è una fila verticale di boat o presunte boat lunga 3, ed è circondata da water, la riconosce come nave intera e decrementa boat_3
(defrule boat_is_limited_3_ver (declare (salience 15))
    (status (step ?s) (currently running))
    ?btf <- (boats_to_find (boat_3 ?n3&~0))

    (cell_updated (x ?x) (y ?y))
    (not (boat_decremented (x ?x) (y ?y)))

    (cell_updated (x ?x1&:(eq ?x1 (+ ?x 1))) (y ?y))
    (cell_updated (x ?x2&:(eq ?x2 (+ ?x 2))) (y ?y))

    (or
        (k-cell (x ?x3&:(eq ?x3 (- ?x 1))) (y ?y) (content water))
        (border (x ?x3&:(eq ?x3 (- ?x 1))) (y ?y)))
    (or
        (k-cell (x ?x4&:(eq ?x4 (+ ?x 3))) (y ?y) (content water))
        (border (x ?x4&:(eq ?x4 (+ ?x 3))) (y ?y)))
=>
    (printout t "boat_is_limited_3_ver" crlf)
    
    (modify ?btf (boat_3 (- ?n3 1)))
    (assert (boat_decremented (x ?x) (y ?y)))
    (assert (boat_decremented (x ?x1) (y ?y)))
    (assert (boat_decremented (x ?x2) (y ?y)))
)


; Se c'è una fila orizzontale di boat o presunte boat lunga 2, ed è circondata da water, la riconosce come nave intera e decrementa boat_2
(defrule boat_is_limited_2_hor (declare (salience 15))
    (status (step ?s) (currently running))
    ?btf <- (boats_to_find (boat_2 ?n2&~0))

    (cell_updated (x ?x) (y ?y))
    (not (boat_decremented (x ?x) (y ?y)))

    (cell_updated (x ?x) (y ?y1&:(eq ?y1 (+ ?y 1))))

    (or
        (k-cell (x ?x) (y ?y2&:(eq ?y2 (- ?y 1))) (content water))
        (border (x ?x) (y ?y2&:(eq ?y2 (- ?y 1)))))
    (or
        (k-cell (x ?x) (y ?y3&:(eq ?y3 (+ ?y 2))) (content water))
        (border (x ?x) (y ?y3&:(eq ?y3 (+ ?y 2)))))
=>
    (printout t "boat_is_limited_2_hor" crlf)

    (modify ?btf (boat_2 (- ?n2 1)))
    (assert (boat_decremented (x ?x) (y ?y)))
    (assert (boat_decremented (x ?x) (y ?y1)))
)


; Quando una boat è circondata verticalmente da water, decrementa il n. boat_2
(defrule boat_is_limited_2_ver (declare (salience 15))
    (status (step ?s) (currently running))
    ?btf <- (boats_to_find (boat_2 ?n2&~0))

    (cell_updated (x ?x) (y ?y))
    (not (boat_decremented (x ?x) (y ?y)))

    (cell_updated (x ?x1&:(eq ?x1 (+ ?x 1))) (y ?y))

    (or
        (k-cell (x ?x2&:(eq ?x2 (- ?x 1))) (y ?y) (content water))
        (border (x ?x2&:(eq ?x2 (- ?x 1))) (y ?y)))
    (or
        (k-cell (x ?x3&:(eq ?x3 (+ ?x 2))) (y ?y) (content water))
        (border (x ?x3&:(eq ?x3 (+ ?x 2))) (y ?y)))
=>
    (printout t "boat_is_limited_2_ver" crlf)

    (modify ?btf (boat_2 (- ?n2 1)))
    (assert (boat_decremented (x ?x) (y ?y)))
    (assert (boat_decremented (x ?x1) (y ?y)))
)


(defrule lasts_distance_1_hor (declare (salience 15))
    (status (step ?s) (currently running))
    ?btf <- (boats_to_find (boat_3 ?n3&~0))

    (k-cell (x ?x) (y ?y) (content left))
    (not (boat_decremented (x ?x) (y ?y)))

    (k-cell (x ?x) (y ?y2&:(eq ?y2 (+ ?y 2))) (content right))
=>
    (printout t "lasts_distance_1_hor" crlf)
    
    (modify ?btf (boat_3 (- ?n3 1)))
    (assert (boat_decremented (x ?x) (y ?y)))
    (assert (boat_decremented (x ?x) (y (+ ?y 1))))
    (assert (boat_decremented (x ?x) (y ?y2)))
)

(defrule lasts_distance_1_ver (declare (salience 15))
    (status (step ?s) (currently running))
    ?btf <- (boats_to_find (boat_3 ?n3&~0))

    (k-cell (x ?x) (y ?y) (content top))
    (not (boat_decremented (x ?x) (y ?y)))

    (k-cell (x ?x2&:(eq ?x2 (+ ?x 2))) (y ?y) (content bot))
=>
    (printout t "lasts_distance_1_ver" crlf)
    
    (modify ?btf (boat_3 (- ?n3 1)))
    (assert (boat_decremented (x ?x) (y ?y)))
    (assert (boat_decremented (x (+ ?x 1)) (y ?y)))
    (assert (boat_decremented (x ?x2) (y ?y)))
)


(defrule last_middle_distance_0_left (declare (salience 15))
    (status (step ?s) (currently running))

    (k-cell (x ?x) (y ?y) (content left))
    (k-cell (x ?x) (y ?y1&:(eq ?y1 (+ ?y 1))) (content middle))
    (action_base_done (x ?x) (y ?y))
    (not (cell_considered (x ?x) (y ?y)))
=>
    (printout t "last_middle_distance_0_left" crlf)
    (next_action_unknown guess ?x (+ ?y 2) horizontal)
    (assert (cell_considered (x ?x) (y ?y)))
    (assert (cell_considered (x ?x) (y ?y1)))
)

(defrule last_middle_distance_0_right (declare (salience 15))
    (status (step ?s) (currently running))

    (k-cell (x ?x) (y ?y) (content right))
    (k-cell (x ?x) (y ?y1&:(eq ?y1 (- ?y 1))) (content middle))
    (action_base_done (x ?x) (y ?y))
    (not (cell_considered (x ?x) (y ?y)))
=>
    (printout t "last_middle_distance_0_right" crlf)
    (next_action_unknown guess ?x (- ?y 2) horizontal)
    (assert (cell_considered (x ?x) (y ?y)))
    (assert (cell_considered (x ?x) (y ?y1)))
)

(defrule last_middle_distance_0_top (declare (salience 15))
    (status (step ?s) (currently running))

    (k-cell (x ?x) (y ?y) (content top))
    (k-cell (x ?x1&:(eq ?x1 (+ ?x 1))) (y ?y) (content middle))
    (action_base_done (x ?x) (y ?y))
    (not (cell_considered (x ?x) (y ?y)))
=>
    (printout t "last_middle_distance_0_top" crlf)
    (next_action_unknown guess (+ ?x 2) ?y vertical)
    (assert (cell_considered (x ?x) (y ?y)))
    (assert (cell_considered (x ?x1) (y ?y)))
)


(defrule last_middle_distance_0_bot (declare (salience 15))
    (status (step ?s) (currently running))

    (k-cell (x ?x) (y ?y) (content bot))
    (k-cell (x ?x1&:(eq ?x1 (- ?x 1))) (y ?y) (content middle))
    (action_base_done (x ?x) (y ?y))
    (not (cell_considered (x ?x) (y ?y)))
=>
    (printout t "last_middle_distance_0_bot" crlf)
    (next_action_unknown guess (- ?x 2) ?y vertical)
    (assert (cell_considered (x ?x) (y ?y)))
    (assert (cell_considered (x ?x1) (y ?y)))
)

(defrule last_middle_distance_1_left (declare (salience 15))
    (status (step ?s) (currently running))
    ?btf <- (boats_to_find (boat_4 1))

    (k-cell (x ?x) (y ?y) (content left))
    (k-cell (x ?x) (y ?y2&:(eq ?y2 (+ ?y 2))) (content middle))
=>
    (printout t "last_middle_distance_1_left" crlf)
    (next_action guess ?x (+ ?y 3) right)

    (modify ?btf (boat_4 0))
    (assert (boat_decremented (x ?x) (y ?y)))
    (assert (boat_decremented (x ?x) (y (+ ?y 1))))
    (assert (boat_decremented (x ?x) (y ?y2)))
    (assert (boat_decremented (x ?x) (y (+ ?y 3))))
)

(defrule last_middle_distance_1_right (declare (salience 15))
    (status (step ?s) (currently running))
    ?btf <- (boats_to_find (boat_4 1))

    (k-cell (x ?x) (y ?y) (content right))
    (k-cell (x ?x) (y ?y2&:(eq ?y2 (- ?y 2))) (content middle))
=>
    (printout t "last_middle_distance_1_right" crlf)
    (next_action guess ?x (- ?y 3) left)

    (modify ?btf (boat_4 0))
    (assert (boat_decremented (x ?x) (y ?y)))
    (assert (boat_decremented (x ?x) (y (- ?y 1))))
    (assert (boat_decremented (x ?x) (y ?y2)))
    (assert (boat_decremented (x ?x) (y (- ?y 3))))
)

(defrule last_middle_distance_1_top (declare (salience 15))
    (status (step ?s) (currently running))
    ?btf <- (boats_to_find (boat_4 1))

    (k-cell (x ?x) (y ?y) (content top))
    (k-cell (x ?x2&:(eq ?x2 (+ ?x 2))) (y ?y) (content middle))
=>
    (printout t "last_middle_distance_1_top" crlf)
    (next_action guess (+ ?x 3) ?y bot)

    (modify ?btf (boat_4 0))
    (assert (boat_decremented (x ?x) (y ?y)))
    (assert (boat_decremented (x (+ ?x 1)) (y ?y)))
    (assert (boat_decremented (x ?x2) (y ?y)))
    (assert (boat_decremented (x (+ ?x 3)) (y ?y)))
)

(defrule last_middle_distance_1_bot (declare (salience 15))
    (status (step ?s) (currently running))
    ?btf <- (boats_to_find (boat_4 1))

    (k-cell (x ?x) (y ?y) (content bot))
    (k-cell (x ?x2&:(eq ?x2 (- ?x 2))) (y ?y) (content middle))
=>
    (printout t "last_middle_distance_1_bot" crlf)
    (next_action guess (- ?x 3) ?y top)

    (modify ?btf (boat_4 0))
    (assert (boat_decremented (x ?x) (y ?y)))
    (assert (boat_decremented (x (- ?x 1)) (y ?y)))
    (assert (boat_decremented (x ?x2) (y ?y)))
    (assert (boat_decremented (x (- ?x 3)) (y ?y)))
)


(defrule middles_distance_0_hor (declare (salience 15))
    (status (step ?s) (currently running))
    ?btf <- (boats_to_find (boat_4 1))

    (k-cell (x ?x) (y ?y) (content middle))
    (k-cell (x ?x) (y ?y1&:(eq ?y1 (+ ?y 1))) (content middle))
=>
    (printout t "middles_distance_0_hor" crlf)
    (next_action guess ?x (- ?y 1) left)
    (next_action guess ?x (+ ?y 2) right)

    (modify ?btf (boat_4 0))
    (assert (boat_decremented (x ?x) (y ?y)))
    (assert (boat_decremented (x ?x) (y ?y1)))
    (assert (boat_decremented (x ?x) (y (- ?y 1))))
    (assert (boat_decremented (x ?x) (y (+ ?y 2))))
)

(defrule middles_distance_0_ver (declare (salience 15))
    (status (step ?s) (currently running))
    ?btf <- (boats_to_find (boat_4 1))

    (k-cell (x ?x) (y ?y) (content middle))
    (k-cell (x ?x1&:(eq ?x1 (+ ?x 1))) (y ?y) (content middle))
=>
    (printout t "middles_distance_0_ver" crlf)
    (next_action guess (- ?x 1) ?y top)
    (next_action guess (+ ?x 2) ?y bot)

    (modify ?btf (boat_4 0))
    (assert (boat_decremented (x ?x) (y ?y)))
    (assert (boat_decremented (x ?x1) (y ?y)))
    (assert (boat_decremented (x (- ?x 1)) (y ?y)))
    (assert (boat_decremented (x (+ ?x 2)) (y ?y)))
)


; In caso boat_4 == 0, aggiorno i valori delle boat_3 orizzontali disponibili
(defrule r4_hor (declare (salience 15))
    (status (step ?s) (currently running))
    ?btf <- (boats_to_find (boat_4 0) (boat_3 ?n3&~0))
    
    (cell_updated (x ?x) (y ?y))
    (not (boat_decremented (x ?x) (y ?y)))

    (cell_updated (x ?x) (y ?y1&:(eq ?y1 (+ ?y 1))))
    (cell_updated (x ?x) (y ?y2&:(eq ?y2 (+ ?y 2))))

    (not (cell_updated (x ?x) (y ?y3&:(eq ?y3 (- ?y 1)))))
    (not (cell_updated (x ?x) (y ?y4&:(eq ?y4 (+ ?y 3)))))
=>
    (printout t "r4_hor" crlf)
    (assert_water ?x (- ?y 1))
    (assert_water ?x (+ ?y 3))

    (modify ?btf (boat_3 (- ?n3 1)))
    (assert (boat_decremented (x ?x) (y ?y)))
    (assert (boat_decremented (x ?x) (y ?y1)))
    (assert (boat_decremented (x ?x) (y ?y2)))

)

; In caso boat_4 == 0 , aggiorno i valori delle boat_3 verticali disponibili
(defrule r4_ver (declare (salience 15))
    (status (step ?s) (currently running))
    ?btf <- (boats_to_find (boat_4 0) (boat_3 ?n3&~0))
    
    (cell_updated (x ?x) (y ?y))
    (not (boat_decremented (x ?x) (y ?y)))
    
    (cell_updated (x ?x1&:(eq ?x1 (+ ?x 1))) (y ?y))
    (cell_updated (x ?x2&:(eq ?x2 (+ ?x 2))) (y ?y))

    (not (cell_updated (x ?x3&:(eq ?x3 (- ?x 1))) (y ?y)))
    (not (cell_updated (x ?x4&:(eq ?x4 (+ ?x 3))) (y ?y)))
=>
    (printout t "r4_ver" crlf)
    (assert_water (- ?x 1) ?y)
    (assert_water (+ ?x 3) ?y)

    (modify ?btf (boat_3 (- ?n3 1)))
    (assert (boat_decremented (x ?x) (y ?y)))
    (assert (boat_decremented (x ?x1) (y ?y)))
    (assert (boat_decremented (x ?x2) (y ?y)))

)


; In caso boat_3 == 0, se ho una fila orizzontale da 3 rimanente è sicuramente quella da 4, quindi guesso la cella laterale
(defrule r3_hor (declare (salience 15))
    (status (step ?s) (currently running))
    ?btf <- (boats_to_find (boat_4 ?n4&~0) (boat_3 0))
    
    (cell_updated (x ?x) (y ?y))
    (not (boat_decremented (x ?x) (y ?y)))

    (cell_updated (x ?x) (y ?y1&:(eq ?y1 (+ ?y 1))))
    (cell_updated (x ?x) (y ?y2&:(eq ?y2 (+ ?y 2))))

    (or 
        (k-cell (x ?x) (y ?y3&:(eq ?y3 (- ?y 1))) (content water))
        (border (x ?x) (y ?y3&:(eq ?y3 (- ?y 1))))
        (k-cell (x ?x) (y ?y4&:(eq ?y4 (+ ?y 3))) (content water))
        (border (x ?x) (y ?y4&:(eq ?y4 (+ ?y 3)))))
=>
    (printout t "r3_hor" crlf)
    (if (is_cell_water_or_inexistent ?x (- ?y 1)) then
        (next_action guess ?x (+ ?y 3) right)
        (assert (boat_decremented (x ?x) (y (+ ?y 3))))
    else
        (next_action guess ?x (- ?y 1) left)
        (assert (boat_decremented (x ?x) (y (- ?y 1))))
    )
    (assert (boat_decremented (x ?x) (y ?y)))
    (assert (boat_decremented (x ?x) (y ?y1)))
    (assert (boat_decremented (x ?x) (y ?y2)))
    (modify ?btf (boat_4 0))
)

; In caso boat_3 == 0, se ho una fila verticale da 3 rimanente è sicuramente quella da 4, quindi guesso la cella laterale
(defrule r3_ver (declare (salience 15))
    (status (step ?s) (currently running))
    ?btf <- (boats_to_find (boat_4 ?n4&~0) (boat_3 0))
    
    (cell_updated (x ?x) (y ?y))
    (not (boat_decremented (x ?x) (y ?y)))
   
    (cell_updated (x ?x1&:(eq ?x1 (+ ?x 1))) (y ?y))
    (cell_updated (x ?x2&:(eq ?x2 (+ ?x 2))) (y ?y))

    (or 
        (k-cell (x ?x3&:(eq ?x3 (- ?x 1))) (y ?y) (content water))
        (border (x ?x3&:(eq ?x3 (- ?x 1))) (y ?y))
        (k-cell (x ?x4&:(eq ?x4 (+ ?x 3))) (y ?y) (content water))
        (border (x ?x4&:(eq ?x4 (+ ?x 3))) (y ?y))
    )
=>
    (printout t "r3_ver" crlf)
    (if (is_cell_water_or_inexistent (- ?x 1) ?y) then
        (next_action guess (+ ?x 3) ?y bot)
        (assert (boat_decremented (x (+ ?x 3)) (y ?y)))
    else
        (next_action guess (- ?x 1) ?y top)
        (assert (boat_decremented (x (- ?x 1)) (y ?y)))
    )
    (assert (boat_decremented (x ?x) (y ?y)))
    (assert (boat_decremented (x ?x1) (y ?y)))
    (assert (boat_decremented (x ?x2) (y ?y)))
    (modify ?btf (boat_4 0))
)

; In caso boat_2 == 0, guess della cella circostante di tutte le file di 2 boat rimanenti (orizzontale)
(defrule r2_hor_1 (declare (salience 15))
    (status (step ?s) (currently running))
    (boats_to_find (boat_4 ?n4&~0) (boat_3 ?n3&~0) (boat_2 0))

    (cell_updated (x ?x) (y ?y))
    (not (boat_decremented (x ?x) (y ?y)))

    (cell_updated (x ?x) (y ?y1&:(eq ?y1 (+ ?y 1))))
    (not (cell_updated (x ?x) (y ?y2&:(eq ?y2 (- ?y 1)))))
    (not (cell_updated (x ?x) (y ?y3&:(eq ?y3 (+ ?y 2)))))

    (not (k-cell (x ?x) (y ?y3&:(eq ?y3 (+ ?y 2))) (content water)))
    (not (border (x ?x) (y ?y3&:(eq ?y3 (+ ?y 2)))))

    (or
        (k-cell (x ?x) (y ?y2&:(eq ?y2 (- ?y 1))) (content water))
        (border (x ?x) (y ?y2&:(eq ?y2 (- ?y 1))))
    )
=>
    (printout t "guess_more_if_boat2_is_zero_hor: " ?x " " ?y crlf)
    (next_action_unknown guess ?x (+ ?y 2) horizontal)

)


(defrule r2_hor_2 (declare (salience 15))
    (status (step ?s) (currently running))
    (boats_to_find (boat_4 ?n4&~0) (boat_3 ?n3&~0) (boat_2 0))

    (cell_updated (x ?x) (y ?y))
    (not (boat_decremented (x ?x) (y ?y)))

    (cell_updated (x ?x) (y ?y1&:(eq ?y1 (+ ?y 1))))
    (not (cell_updated (x ?x) (y ?y2&:(eq ?y2 (- ?y 1)))))
    (not (cell_updated (x ?x) (y ?y3&:(eq ?y3 (+ ?y 2)))))

    (not (k-cell (x ?x) (y ?y2&:(eq ?y2 (- ?y 1))) (content water)))
    (not (border (x ?x) (y ?y2&:(eq ?y2 (- ?y 1)))))

    (or
        (k-cell (x ?x) (y ?y3&:(eq ?y3 (+ ?y 2))) (content water))
        (border (x ?x) (y ?y3&:(eq ?y3 (+ ?y 2))))
    )
=>
    (printout t "guess_more_if_boat2_is_zero_hor: " ?x " " ?y crlf)
    (next_action_unknown guess ?x (- ?y 1) horizontal)

)

; In caso boat_2 == 0, guess della cella circostante di tutte le file di 2 boat rimanenti (verticale)
(defrule r2_ver_1 (declare (salience 15))
    (status (step ?s) (currently running))
    (boats_to_find (boat_4 ?n4&~0) (boat_3 ?n3&~0) (boat_2 0))

    (cell_updated (x ?x) (y ?y))
    (not (boat_decremented (x ?x) (y ?y)))

    (cell_updated (x ?x1&:(eq ?x1 (+ ?x 1))) (y ?y))
    (not (cell_updated (x ?x2&:(eq ?x2 (- ?x 1))) (y ?y)))
    (not (cell_updated (x ?x3&:(eq ?x3 (+ ?x 2))) (y ?y)))

    (not (k-cell (x ?x3&:(eq ?x3 (+ ?x 2))) (y ?y) (content water)))
    (not (border (x ?x3&:(eq ?x3 (+ ?x 2))) (y ?y)))

    (or
        (k-cell (x ?x2&:(eq ?x2 (- ?x 1))) (y ?y) (content water))
        (border (x ?x2&:(eq ?x2 (- ?x 1))) (y ?y))
    )
=>
    (printout t "guess_more_if_boat2_is_zero_ver: " ?x " " ?y crlf)
    (next_action_unknown guess (+ ?x 2) ?y vertical)
)


(defrule r2_ver_2 (declare (salience 15))
    (status (step ?s) (currently running))
    (boats_to_find (boat_4 ?n4&~0) (boat_3 ?n3&~0) (boat_2 0))

    (cell_updated (x ?x) (y ?y))
    (not (boat_decremented (x ?x) (y ?y)))

    (cell_updated (x ?x1&:(eq ?x1 (+ ?x 1))) (y ?y))
    (not (cell_updated (x ?x2&:(eq ?x2 (- ?x 1))) (y ?y)))
    (not (cell_updated (x ?x3&:(eq ?x3 (+ ?x 2))) (y ?y)))

    (not (k-cell (x ?x2&:(eq ?x2 (- ?x 1))) (y ?y) (content water)))
    (not (border (x ?x2&:(eq ?x2 (- ?x 1))) (y ?y)))

    (or
        (k-cell (x ?x3&:(eq ?x3 (+ ?x 2))) (y ?y) (content water))
        (border (x ?x3&:(eq ?x3 (+ ?x 2))) (y ?y))
    )
=>
    (printout t "guess_more_if_boat2_is_zero_ver: " ?x " " ?y crlf)
    (next_action_unknown guess (- ?x 1) ?y vertical)
)


; KNOWLEDGE EXPANSION DA K-CELL (UNCERTAINTY)

(defrule fire_from_last
	(status (step ?s) (currently running))
    (moves (fires ?nf &:(> ?nf 0)))
	(k-cell (x ?x) (y ?y) (content ?content&~sub&~middle&~water))
	(not (boat_decremented (x ?x) (y ?y)))
=>
    (printout t "fire_from_last: " ?x " " ?y crlf)
    (switch ?content
        (case top then
            (next_action fire (+ ?x 2) ?y none))
        (case bot then
            (next_action fire (- ?x 2) ?y none))
        (case left then
            (next_action fire ?x (+ ?y 2) none))
        (case right then
            (next_action fire ?x (- ?y 2) none))
    )
)

(defrule infer_middle_direction_with_probability
    (status (step ?s) (currently running))
    (k-cell (x ?x) (y ?y) (content middle))
    (not (cell_considered (x ?x) (y ?y)))
=>
    (printout t "infer_middle_direction_with_probability: " ?x " " ?y crlf)
    (bind ?hor_prob (+ (kp_sum ?x (- ?y 1)) (kp_sum ?x (+ ?y 1))))
    (bind ?ver_prob (+ (kp_sum (- ?x 1) ?y) (kp_sum (+ ?x 1) ?y)))
    (if (> ?hor_prob ?ver_prob) then
        (next_action_unknown guess ?x (- ?y 1) horizontal)
        (next_action_unknown guess ?x (+ ?y 1) horizontal)
    else
        (next_action_unknown guess (- ?x 1) ?y vertical)
        (next_action_unknown guess (+ ?x 1) ?y vertical)
    )
    (assert (cell_considered (x ?x) (y ?y)))
)




; UNKNOWN

(defrule fire_most_prob (declare (salience -50))
    (status (step ?s) (currently running))
    (moves (fires ?nf &:(> ?nf 0)))
=>  
    (bind ?cell (most_prob_cell))
    (bind ?x (nth$ 1 ?cell))
    (bind ?y (nth$ 2 ?cell))
    (if (and (neq ?x FALSE) (neq ?y FALSE)) then
        (printout t "FIRE MOST PROB - x: " ?x " y: " ?y crlf)
        (next_action fire ?x ?y none)
    else
        (assert (exec (step ?s) (action solve)))
	    (pop-focus)
    )
)

(defrule check_if_fired_is_water
    (status (step ?s) (currently running))
    ?f <- (fired (x ?x) (y ?y))
=>
    (if (not (any-factp ((?kc k-cell)) (and (eq ?x ?kc:x) (eq ?y ?kc:y)))) then
        (assert_water ?x ?y)
    )
    (retract ?f)
)

(defrule guess_most_prob (declare (salience -5))
    (status (step ?s) (currently running))
    (moves (fires 0) (guesses ?ng&:(> ?ng 0)))
=>
    (bind ?cell (most_prob_cell))
    (bind ?x (nth$ 1 ?cell))
    (bind ?y (nth$ 2 ?cell))
    (if (and (neq ?x FALSE) (neq ?y FALSE)) then
        (printout t "guess_most_prob: " ?x " " ?y crlf)
        (next_action guess ?x ?y none)
    )
)


; FINAL RULES

(defrule finished (declare (salience 100))
    (status (step ?s) (currently running))
    (moves (fires 0) (guesses 0))
=>
    (assert (exec (step ?s) (action solve)))
	(pop-focus)
)


(defrule finished_2 (declare (salience 100))
    (status (step ?s) (currently running))
    (boats_to_find (boat_4 0) (boat_3 0) (boat_2 0) (boat_1 0))
=>
    (printout t "boat_1: 0, boat_2: 0, boat_3: 0, boat_4: 0" crlf)
    (assert (exec (step ?s) (action solve)))
	(pop-focus)
)

(defrule out_of_alternatives (declare (salience -100))
    (status (step ?s) (currently running))
=>
    
    (assert (exec (step ?s) (action solve)))
	(pop-focus)
)