/* 	Query 1 - Indicare nome e cognome dei clienti che hanno ordinato tutti gli articoli della categoria “fumetti” */


/*SELECT nome, cognome
FROM biblioteca.cliente
WHERE EXISTS (SELECT *
			  FROM biblioteca.articolo
              WHERE articolo.categoria = 'fumetto')
AND NOT EXISTS (SELECT * 
				  FROM biblioteca.articolo 
				  WHERE articolo.categoria = 'fumetto' 
                  AND NOT EXISTS(SELECT * 
								   FROM biblioteca.prestito
                                   WHERE articolo.ID = prestito.id_articolo
                                   AND prestito.cf_cliente = cliente.codice_fiscale)
					);*/
                    
                    

/* Query 2 - Indicare nome e ID degli articoli presi in prestito e non ancora restituiti */


/*	SELECT nome, ID
	FROM biblioteca.articolo
	WHERE articolo.ID IN (SELECT id_articolo
							FROM biblioteca.prestito
							WHERE articolo.ID = prestito.id_articolo
							AND prestito.data_restituzione IS NULL); */


/* Query 3 - Indicare nome e numero di spettatori degli eventi con il maggior numero di spettatori */
	
	/*SELECT nome, spettatori
	FROM biblioteca.evento
	WHERE spettatori = ( SELECT MAX(spettatori)
							FROM biblioteca.evento );*/

/* Query 4 - Indicare il nome degli articoli che sono stati prenotati e il nome dei clienti che li hanno prenotati  */
	/*SELECT c.nome, c.cognome, a.nome
	FROM biblioteca.cliente c, biblioteca.articolo a, biblioteca.prenotazione p
	WHERE p.id_articolo = a.ID 
	AND p.cf_cliente = c.codice_fiscale;*/



/* Query 5 - Indicare il nome e il cognome di quei volontari che hanno organizzato l’evento e l’hanno anche presentato*/

	/*SELECT nome, cognome
	FROM biblioteca.volontario
	WHERE matricola IN (SELECT id_presentatore
							FROM biblioteca.evento
							WHERE evento.id_organizzatore = volontario.matricola
							AND  id_organizzatore = id_presentatore  );*/