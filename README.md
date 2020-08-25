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
- Sono stati modellati 3 agenti, differenti per il grado di complessità della strategia da loro utilizzata: `3_Agent.clp`, `3_Agent_1.clp` e `3_Agent_2.clp`.
- Le mappe generate per il testing sono `2_mapEnvironment.clp` e `2_mapEnvironment2.clp`

I restanti file sono stati creati dal professore per la gestione del gioco, tra cui `1_Env.clp` che gestisce l'ambiente di gioco e `0_Main.clp` che gestisce l'interscambio tra agente e ambiente.

## Agente 1
Il primo agente adotta una strategia molto semplice. Utilizzando i dati del campo da gioco concessi dall'ambiente, e quindi il numero di pezzi di nave presenti per ogni riga e colonna (`k-per-row` e `k-per-col`), calcola le prime 20 celle più probabili ed effettua una _guess_. Non effettua alcuna _fire_ in quanto la penalità in caso di _miss_ sarebbe più alta.

**Conoscenza**

La conoscenza è stata modellata definendo il template `cell_prob` che misura la probabilità di trovare un pezzo di nave in una specifica cella. Viene asserito un nuovo fatto ordinato per tutte le celle.

**Regole di expertise**

Le regole di expertise importanti sono due:
- `calc_cell_values` calcola per ogni cella di gioco, la probabilità che contenga un pezzo di nave.
- `guess_best` utilizza la `cell_prob` di maggior valore e ne effettua la _guess_.

**Limiti**

Ovviamente, adottando una strategia così semplice, che non tiene conto di molti dati messi a disposizione dall'ambiente, i suoi limiti sono molti. Come ci si aspetta ottiene punteggi di basso valore.

## Agente 2
Il secondo agente adotta una strategia più complessa.

Sfrutta maggiormente i dati concessi dall'ambiente, come la disposizione delle celle conosciute inizialmente. Infatti prende decisioni in base alle celle di cui è venuto a conoscenza, ad eccezione di `water`. Distingue tra pezzi diversi cercando di identificare il tipo e l'orientamento della nave attraverso le informazioni conseguenti alle _fires_. Le _guesses_ vengono effettuate solamente in condizione di certezza.

Inoltre memorizza l'informazione relativa al numero di navi abbattute e rimanenti, migliorando l'individuazione delle celle rimanenti utilizzando quindi meno _fires_.

Per maggiore chiarezza, consultare la [Strategia 2](https://github.com/lorenzofavaro/IA-Clips/blob/master/utils/Strategia2.txt) relativa a questo agente.

**Conoscenza**

Sono stati definiti varie tipologie di fatti per la gestione della conoscenza, tra cui:
- `boats_to_find` che memorizza per ogni tipologia di nave, quante ne devono essere ancora trovate. Ad inizio gioco viene definito il seguente fatto:
  - `(boat_4 1)`
  - `(boat_3 2)`
  - `(boat_2 3)`
  - `(boat_1 4)`
- `cell_prob` rappresenta per ogni cella la probabilità che contenga un pezzo di nave.
- `cell_to_see` è utilizzato per definire su quali celle agire tramite una _guess_/_fire_.
- `cell_considered` marca la cella come già presa in esame in modo che non venga più considerata.
- `rule_in_progress` è utile all'agente a riconoscere se è in corso una sequenza di azioni specifica, in modo da non interromperla.

**Regole di expertise**


**Limiti**


## Agente 3
La conoscenza è stata modellata definendo per ogni cella del campo di gioco, alcuni fatti non ordinati:
- `cell_to_see` è utilizzato per definire su quali celle agire tramite una _guess_/_fire_.
- `cell_considered` marca la cella come già presa in esame in modo che non venga più considerata.
- `cell_updated` è usata per segnare le celle che sono state oggetto di _guess_/_fire_.
- `cell_watered` segna le celle a cui è stata già aggiunta l'acqua intorno in quanto riconosciuta come parte di una nave verticale/orizzontale.
- `boat_decremented` riconosce la cella come facente parte in una nave orizzontale/verticale.
- `action_base_done` è usato per tenere conto che l'azione di base dei _last_ (celle terminali di una nave) è stata effettuata.
- `border` rappresenta il bordo del campo da gioco.
- `fired` segna la cella su cui è stata effettuata una _fire_.
- `guessed` segna la cella su cui è stata effettuata una _guess_.
