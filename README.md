# Progetto Clips
Questo progetto è stato realizzato per l'esame di Intelligenza Artificiale e Laboratorio del corso di Laurea Magistrale all'Università di Torino.

## Setup
- Installare [Clips](http://clipsrules.sourceforge.net/).
- Installare [VSCode](https://code.visualstudio.com/download) e l'apposita estensione [Clips Language support](https://marketplace.visualstudio.com/items?itemName=nerg.clips-lang).
- Clonare il progetto

## Il problema
L’obiettivo del progetto è quello di sviluppare un sistema esperto che giochi ad una versione
semplificata della famigerata _Battaglia Navale_.
Il gioco è nella versione “in-solitario”, per cui c’è un solo giocatore (il vostro sistema esperto) che
deve indovinare la posizione di una flotta di navi distribuite su una griglia 10x10.
Come di consueto le navi da individuare sono le seguenti:

- 1 corazzata da 4 caselle
- 2 incrociatori da 3 caselle ciascuno
- 3 cacciatorpedinieri da 2 caselle ciascuno
- 4 sottomarini da 1 casella ciascuno

Le navi saranno, ovviamente, posizionate in verticale o in orizzantale e deve esserci almeno una
cella libera (cioè con dell’acqua) tra due navi.
Per rendere più semplice il problema, il contenuto di alcune celle sarà noto fin dall’inizio. Inoltre, in
corrispondenza di ciascuna riga e colonna sarà indicato il numero di celle che contengono navi.
Ad esempio, la seguente situazione rappresenta un possibile stato iniziale del problema.

<p align="center">
  <img src="https://github.com/lorenzofavaro/IA-Clips/blob/master/utils/campo.png"/>
</p>

Sapete quindi che in posizione [7, 1] c’è dell’acqua, in posizione [6, 5] c’è un sottomarino, in
posizione [5, 10] c’è un pezzo di nave che probabilmente continuerà nelle celle subito sopra e
subito sotto. Sapete inoltre, che nella prima riga due celle sono occupate da una nave, mentre nella
prima colonna sono 5, ecc.

Il vostro sistema esperto avrà quattro possibili azioni:

- _fire_ x y
- _guess_ x y
- _unguess_ x y
- _solve_

L’azione _fire_ è l’equivalente di un’azione percettiva e vi permette di vedere il contenuto della cella
[x, y].
L’azione _guess_ serve per indicare che il vostro sistema esperto ritiene ci sia una nave in posizione
[x, y]. Questa azione è da considerarsi un’ipotesi, per cui è ritrattabile in un momento successivo,
cioè il vostro sistema esperto potrebbe tornare sui suoi passi con il comando _unguess_.


Il comando _solve_ è da usarsi solo quando il vostro sistema esperto ritiene di aver risolto il gioco,
l’azione termina il gioco attivando il calcolo del punteggio secondo la seguente formula:

`( 10 ∗ fok + 10 ∗ gok + 15 ∗ sink )−( 25 ∗ fko + 15 ∗ gko + 10 ∗ safe )`
dove:

- fok è il numero di azioni fire che sono andate a segno
- gok è il numero di celle guessed corrette
- sink è il numero di navi totalemente affondate
- fko è il numero di azioni fire andate in acqua
- gko è il numero di celle guessed errate
- safe è il numero di celle che contengono una porzione di nave e che sono rimaste inviolate (né
guessed né fired)

Per rendere le cose un po’ più interessanti, avete solamente 5 _fire_ a disposizione. Inoltre, in un dato
momento non possono esserci più di venti caselle marcate “guessed”.
Lo scopo del gioco è quindi marcare tutte le caselle che contengono una nave come guessed, o
eventualmente averle colpite con _fire_.

## Struttura del progetto
- `battlemap` contiene tutto il necessario per la generazione di mappe da gioco.
- `utils` contiene le strategie utilizzate dai tre agenti ed anche alcuni file secondari.
- `maps` contiene tutte le mappe generate ed utilizzate per il testing degli agenti.
- Sono stati modellati 3 agenti, differenti per il grado di complessità della strategia da loro utilizzata: `2_Agent.clp`, `2_Agent_1.clp` e `2_Agent_2.clp`.

I restanti file sono stati creati dal professore per la gestione del gioco, tra cui `1_Env.clp` che gestisce l'ambiente di gioco e `0_Main.clp` che gestisce l'interscambio tra agente e ambiente.

## Agente 1
Il primo agente adotta una strategia molto semplice. Utilizzando i dati del campo da gioco concessi dall'ambiente, e quindi il numero di pezzi di nave presenti per ogni riga e colonna (`k-per-row` e `k-per-col`), calcola le prime 25 celle più probabili ed effettua una _fire_ delle prime 5, dopodichè 20 _guesses_ in ordine di probabilità.

### Conoscenza
La conoscenza è stata modellata definendo `cell_prob` che misura la probabilità di trovare un pezzo di nave in una specifica cella. Viene asserito un nuovo fatto ordinato per tutte le celle.

### Regole di expertise
Le regole di expertise importanti sono due:
- `calc_cell_values` calcola per ogni cella di gioco, la probabilità che contenga un pezzo di nave.
- `fire_best` utilizza la `cell_prob` di maggior valore e ne effettua la _fire_.
- `guess_best` utilizza la `cell_prob` di maggior valore e ne effettua la _guess_.

### Funzioni
Sono state utilizzate due funzioni: `greater_than(?f1 ?f2)`, ossia un comparatore tra due fatti, in questo caso `cell_prob`; `find_max(?template ?predicate)` che permette di trovare la cella con probabilità maggiore. 

### Limiti
Ovviamente, adottando una strategia così semplice, che non tiene conto di molti dati messi a disposizione dall'ambiente, i suoi limiti sono molti. Come ci si aspetta ottiene punteggi di basso valore.

## Agente 2
Il secondo agente adotta una strategia più complessa.

Sfrutta maggiormente i dati concessi dall'ambiente, come la disposizione delle celle conosciute inizialmente. Infatti prende decisioni in base alle celle di cui è venuto a conoscenza, ad eccezione di `water`. Distingue tra pezzi diversi cercando di identificare il tipo e l'orientamento della nave attraverso le informazioni conseguenti alle _fires_. Le _guesses_ vengono effettuate solamente in condizione di certezza.

Inoltre memorizza l'informazione relativa al numero di navi abbattute e rimanenti, migliorando l'individuazione delle celle rimanenti utilizzando quindi meno _fires_.

Per maggiore chiarezza, consultare la [strategia](https://github.com/lorenzofavaro/IA-Clips/blob/master/utils/Strategia2.txt) relativa a questo agente.

### Conoscenza
Sono state definite varie tipologie di fatti per la gestione della conoscenza, tra cui:
- `boats_to_find` che memorizza per ogni tipologia di nave, quante ne devono essere ancora trovate. Ad inizio gioco viene così definito: `(deffacts total_boats (boats_to_find (boat_4 1) (boat_3 2) (boat_2 3) (boat_1 4)))`.
- `cell_prob` rappresenta per ogni cella la probabilità che contenga un pezzo di nave.
- `cell_to_see` è utilizzato per definire su quali celle agire tramite una _guess_/_fire_.
- `cell_considered` marca la cella come già presa in esame in modo che non venga più considerata.
- `rule_in_progress` è utile all'agente a riconoscere se è in corso una sequenza di azioni specifica, in modo da non interromperla.

### Regole di expertise
La regola più importante è `action_to_do` (infatti ha salience 30) che interviene appena un fatto `cell_to_see` viene asserito ed effettua l'azione specificata sulla cella specificata. Il fatto ordinato `cell_to_see` viene asserito dall'agente in base alla situazione in cui si trova.

Sono presenti alcune regole che gestiscono ciascuna una diversa situazione, come ad esempio nel caso di `r43` che definisce l'azione da effettuare nel caso in cui siano state affondate le navi da 4 e 3 pezzi e si sia a conoscenza di un pezzo di nave terminale. Per alcune situazioni di questo tipo, sono state definite delle regole ausiliarie (con il suffisso `_aux`) poichè non è sufficiente singola azione.

Nel caso in cui l'agente non abbia dati utili da gestire, viene attivata la regola `unknown` che cerca di individuare nuove navi effettuando _fires_ sulle celle più probabili, sfruttando lo stesso meccanismo del primo agente.

Infine, l'agente termina attraverso la regola `out_of_fires` non appena esaurisce tutte le _fires_ a sua disposizione.

### Funzioni
Si è cercato di limitare il numero di funzioni al minimo, quelle più importanti sono le seguenti:
- `next_action(?action ?x ?y ?content ?diff)` semplifica l'esecuzione della `action` nel caso in cui si stia trattando un pezzo di nave terminale. Infatti prendendo in input il `content` della cella e le sue coordinate, calcola la cella a distanza `diff` evitando di gestire la diversità di ogni pezzo che si sta trattando in ogni regola.
- `max_prob_neighbour(?x ?y)` è utilizzato nel caso in cui l'agente sia a conoscenza di una cella il cui `content` è `middle`. In questo caso l'agente calcola in quale delle quattro celle circostanti è più probabile che si trovi un altro pezzo di nave, individuando così l'orientamento della stessa. Per adempiere al compito utilizza ancora una volta i dati `k-per-row` e `k-per-col`.

### Limiti
Uno dei limiti più penalizzanti si ha quando nella mappa non sono presenti celle conosciute, in quel caso l'agente utilizzerà le _fires_ per individuare navi. Nel caso in cui non dovesse trovarne nemmeno una, otterrebbe un punteggio molto basso. Inoltre, nel caso in cui trovasse tante navi di tipo diverso, non riuscirebbe a ricondursi ad alcuna regola che si basa sulla conoscenza di navi affondate. 

## Agente 3
Il terzo ed ultimo agente utilizza la strategia più sofisticata tra tutti.

Divide il suo processo in due macrofasi:
1. Ragionamento ed Inferenza (Certainty)
    1. Routine
    2. Inferenza da k-per-*
    3. Riconoscimento navi
    4. Inferenza da navi affondate
    5. Inferenza da k-cell
2. Espansione della conoscenza (Uncertainty)
    1. Da k-cell
    2. Senza evidenze

Per maggiore chiarezza, consultare la [strategia](https://github.com/lorenzofavaro/IA-Clips/blob/master/utils/Strategia3.txt) relativa a questo agente.

### Conoscenza
La conoscenza è stata modellata definendo per ogni cella del campo di gioco alcune tipologie di fatti:
- `cell_to_see` è utilizzato per definire su quali celle agire tramite una _guess_/_fire_.
- `cell_considered` marca la cella come già presa in esame in modo che non venga più considerata.
- `cell_updated` è usata per segnare le celle che sono state oggetto di _guess_/_fire_.
- `cell_watered` segna le celle a cui è stata già aggiunta l'acqua intorno in quanto riconosciuta come parte di una nave verticale/orizzontale.
- `boat_decremented` riconosce la cella come facente parte in una nave orizzontale/verticale.
- `action_base_done` è usato per tenere conto che l'azione di base dei _last_ (celle terminali di una nave) è stata effettuata.
- `border` rappresenta il bordo del campo da gioco.
- `fired` segna la cella su cui è stata effettuata una _fire_.
- `guessed` segna la cella su cui è stata effettuata una _guess_.

### Regole di expertise

#### Ragionamento ed Inferenza (Certainty)

Routine:
- `action_to_do` interviene appena un fatto `cell_to_see` viene asserito ed effettua l'azione specificata sulla cella specificata.
- `update_kcp` per ogni `k-cell`/`guessed` decrementa il `k-per-row` ed il `k-per-col`.
- `water_cell` si attiva quando l'agente tratta una `k-cell` che contiene un pezzo di nave terminale o un sottomarino, e asserisce nuovi fatti `k-cell` con contenuto `water` attorno ad essa. I `middle` non vengono trattati in questa regola in quanto la loro gestione dipende da caso a caso e dal loro orientamento.

Inferenza da k-per-*:
- `zero_kp*` agisce quando una `k-per-*` è 0. Per ogni cella di quella riga/colonna il cui contenuto è sconosciuto, asserisce un nuovo fatto `k-cell` dal contenuto `water`.
- `rest_available_*` interviene quando il numero di celle di una riga/colonna dal contenuto sconosciuto è uguale al valore di `k-per-*`; effettua una _guess_ per ciascuna di esse.

Riconoscimento navi:
- `sub_found` classifica come sottomarino una cella _guessed_ se circondato da `water` o da `border`.
- `sub_kcell` si accorge della presenza di un _sub_ da `k-cell` e lo classifica come tale asserendo `boat_decremented` per quella cella e decrementando `boats_to_find (boat_1 ?x)`.
- `boat_is_limited_2_*` classifica una sequenza di 2 celle come nave se circondata da `water` o da `border`.
- `boat_is_limited_3_*` classifica una sequenza di 3 celle come nave se circondata da `water` o da `border`.
- `lasts_distance_1_*` riconosce una nave da 3 pezzi, quando trova 2 _last_ opposti a distanza 1 tra di loro.
- `boat_is_long_4_*` riconosce la corazzata non appena si è in presenza di 4 pezzi di nave consecutivi asserendo `boat_decremented` per ogni cella e decrementando `boats_to_find (boat_4 ?x)`.
- `middles_distance_0_*` individua una corazzata quando si accorge di due `middle` attaccati. Effettua le _guesses_ e decrementa il contatore delle navi da 4.
- `last_middle_distance_1_*` riconosce la presenza di una corazzata quando nota la presenza di un _last_ ed un `middle` allineati a distanza 1, effettua le _guesses_ e decrementa la `boats_to_find (boat_4 ?x)`.

Inferenza da navi affondate:
- `r4_*` si attiva quando la corazzata è stata affondata ma non i due incrociatori, aggiorna il contatore degli incrociatori nel qualcaso si sia a conoscenza di una sequenza di 3 celle contigue contenenti pezzi di nave.
- `r3_*` interviene quando i due incrociatori sono stati affondati ma non la corazzata, sapendo che se c'è una sequenza di 3 celle consecutive marcate come pezzi di nave, fanno sicuramente parte della corazzata. Effettua una _guess_ su una delle due celle laterali e decrementa il contatore della corazzata, ritenendola adesso affondata.
- `r2_*` effettua la _guess_ delle celle laterali delle sequenze di celle marcate come navi, nel momento in cui tutti cacciatorpedinieri sono stati affondati ma rimangono la corazzata o gli incrociatori.

Inferenza da k-cell:
- `last_middle_distance_0_*` effettua la _guess_ della cella a fianco di `middle` quando al fianco opposto è presente un _last_. Dopodichè "copre" d'acqua le celle laterali.
- `r_last_action_base` effettua la guess della cella adiacente ad una `k-cell` che contiene un pezzo di nave terminale.
- `r_middle_border_*` si attiva in presenza di una `k-cell` contenente un `middle` ai bordi della mappa ed effettua la _guess_ delle celle adiacenti.
- `r_middle_water_*` inferisce la direzione di una nave non appena si trovi una `k-cell` contenente `water` vicino ad un `middle`.

#### Espansione della Conoscenza (Uncertainty)

Da k-cell:
- `fire_from_last` effettua una _fire_ a distanza 2 da una cella _last_ conosciuta.
- `infer_middle_direction_with_probability` si attiva quando non si hanno altre conoscenze riguardo i vicini di un `middle`. Viene effettuata la _guess_ di una delle 4 celle adiacenti guardando le probabilità date da `k-per-row` e `k-per-col`.

Senza evidenze:
- `fire_most_prob` effettua una _fire_ sulla cella più probabile.
- `guess_most_prob` effettua una _guess_ sulla cella più probabile.

### Funzioni
Nonostante si sia cercato di ridurre al minimo il numero di funzioni, ne sono presenti alcune:
- `water_around(?x ?y ?content)` data una cella contenente un _last_ o un _sub_ la circonda di acqua asserendo fatti ordinati `k-cell` contenenti `water`.
- `water_around_unknown(?x ?y ?orientation)` è utilizzato quando non si sa che pezzo di nave si stia trattando, tuttavia ne si conosce l'orientamento. Circonda le sei celle laterali di `water`.
- `next_action(?action ?x ?y ?content)` controlla se la cella sia valida e non sia una conosciuta. Dopodichè asserisce `cell_to_see` di modo che la regola `action_to_do` venga attivata e utilizza `water_around sulla cella specificata`.
- `next_action_unknown(?action ?x ?x ?orientation)` ha lo stesso comportamento della precedente ma utilizza `water_around_unknown`.
- `guess_rest(?type ?value ?n_available)` effettua la _guess_ delle `?n_available` celle nella `?value`esima `?type` (riga o colonna).
- `most_prob_cell()` restituisce la cella che più probabilmente contiene un pezzo di nave, avvalendosi della conoscenza acquisita e della k-per-*.

### Limiti
In base alla disposizione delle navi e dalla conoscenza iniziale l'agente performa in maniera diversa. Solitamente produce buoni risultati, tuttavia in alcuni casi, in assenza di celle conosciute fin dall'inizio può produrre risultati molto scadenti.


## Risultati ottenuti
Sono stati effettuati numerosi test, trattando diverse mappe e affidando agli agenti diversa conoscenza iniziale sulle celle della mappa.

### Mappa 1

<p align="center">
  <img src="https://github.com/lorenzofavaro/IA-Clips/blob/master/maps/1_map.png"/>
</p>

<table><thead><tr><th></th><th>Agente 1</th><th>Agente 2</th><th>Agente 3</th></tr></thead><tbody><tr><td>Fire ok</td><td>4</td><td>4</td><td>4</td></tr><tr><td>Fire ko</td><td>1</td><td>1</td><td>1</td></tr><tr><td>Guess ok</td><td>10</td><td>4</td><td>14</td></tr><tr><td>Guess ko</td><td>10</td><td>0</td><td>0</td></tr><tr><td>Celle safe</td><td>4</td><td>10</td><td>0</td></tr><tr><td>Navi affondate</td><td>6</td><td>4</td><td>10</td></tr><tr><td colspan="4"></td></tr><tr><td>Punteggio</td><td>30</td><td>15</td><td>305</td></tr></tbody></table>

### Mappa 2

<p align="center">
  <img src="https://github.com/lorenzofavaro/IA-Clips/blob/master/maps/2_map.png"/>
</p>

<table><thead><tr><th></th><th>Agente 1</th><th>Agente 2</th><th>Agente 3</th></tr></thead><tbody><tr><td>Fire ok</td><td>3</td><td>2</td><td>4</td></tr><tr><td>Fire ko</td><td>2</td><td>3</td><td>1</td></tr><tr><td>Guess ok</td><td>7</td><td>2</td><td>10</td></tr><tr><td>Guess ko</td><td>13</td><td>0</td><td>4</td></tr><tr><td>Celle safe</td><td>8</td><td>14<br></td><td>4</td></tr><tr><td>Navi affondate</td><td>4</td><td>3</td><td>6</td></tr><tr><td colspan="4"></td></tr><tr><td>Punteggio</td><td>-140</td><td>-130</td><td>105</td></tr></tbody></table>




### Mappa 3

<p align="center">
  <img src="https://github.com/lorenzofavaro/IA-Clips/blob/master/maps/3_map.png"/>
</p>

<table><thead><tr><th></th><th>Agente 1</th><th>Agente 2</th><th>Agente 3</th></tr></thead><tbody><tr><td>Fire ok</td><td>4</td><td>2</td><td>4</td></tr><tr><td>Fire ko</td><td>1</td><td>3</td><td>1</td></tr><tr><td>Guess ok</td><td>12</td><td>2</td><td>13</td></tr><tr><td>Guess ko</td><td>8</td><td>0</td><td>4</td></tr><tr><td>Celle safe</td><td>5</td><td>17</td><td>4</td></tr><tr><td>Navi affondate</td><td>8</td><td>2</td><td>7</td></tr><tr><td colspan="4"></td></tr><tr><td>Punteggio</td><td>85</td><td>-175</td><td>150</td></tr></tbody></table>

### Mappa 3 versione 1

<p align="center">
  <img src="https://github.com/lorenzofavaro/IA-Clips/blob/master/maps/3_map_1.png"/>
</p>

<table><thead><tr><th></th><th>Agente 1</th><th>Agente 2</th><th>Agente 3</th></tr></thead><tbody><tr><td>Fire ok</td><td>4</td><td>3</td><td>4</td></tr><tr><td>Fire ko</td><td>1</td><td>2</td><td>1</td></tr><tr><td>Guess ok</td><td>11</td><td>4</td><td>14</td></tr><tr><td>Guess ko</td><td>9</td><td>0</td><td>3</td></tr><tr><td>Celle safe</td><td>6</td><td>14<br></td><td>3</td></tr><tr><td>Navi affondate</td><td>7</td><td>3</td><td>8</td></tr><tr><td colspan="4"></td></tr><tr><td>Punteggio</td><td>50</td><td>-75</td><td>200</td></tr></tbody></table>


### Mappa 3 versione 2

<p align="center">
  <img src="https://github.com/lorenzofavaro/IA-Clips/blob/master/maps/3_map_2.png"/>
</p>

<table><thead><tr><th></th><th>Agente 1</th><th>Agente 2</th><th>Agente 3</th></tr></thead><tbody><tr><td>Fire ok</td><td>4</td><td>4</td><td>4</td></tr><tr><td>Fire ko</td><td>1</td><td>1</td><td>1</td></tr><tr><td>Guess ok</td><td>11</td><td>3</td><td>14</td></tr><tr><td>Guess ko</td><td>9</td><td>0</td><td>3</td></tr><tr><td>Celle safe</td><td>6</td><td>14<br></td><td>3</td></tr><tr><td>Navi affondate</td><td>7</td><td>3</td><td>8</td></tr><tr><td colspan="4"></td></tr><tr><td>Punteggio</td><td>50</td><td>-50</td><td>200</td></tr></tbody></table>


### Mappa 3 versione 3

<p align="center">
  <img src="https://github.com/lorenzofavaro/IA-Clips/blob/master/maps/3_map_3.png"/>
</p>

<table><thead><tr><th></th><th>Agente 1</th><th>Agente 2</th><th>Agente 3</th></tr></thead><tbody><tr><td>Fire ok</td><td>3</td><td>3</td><td>3</td></tr><tr><td>Fire ko</td><td>2</td><td>2</td><td>2</td></tr><tr><td>Guess ok</td><td>11</td><td>4</td><td>15</td></tr><tr><td>Guess ko</td><td>9<br></td><td>0</td><td>2</td></tr><tr><td>Celle safe</td><td>6</td><td>13</td><td>2</td></tr><tr><td>Navi affondate</td><td>7</td><td>3</td><td>9</td></tr><tr><td colspan="4"></td></tr><tr><td>Punteggio</td><td>40</td><td>-65</td><td>215</td></tr></tbody></table>
