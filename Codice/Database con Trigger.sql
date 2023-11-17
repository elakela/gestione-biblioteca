DROP DATABASE IF EXISTS `Biblioteca`;
CREATE DATABASE IF NOT EXISTS `Biblioteca`;
USE `Biblioteca`;

CREATE TABLE IF NOT EXISTS `Biblioteca`.`Cliente` (
    `codice_fiscale`   CHAR(16)     NOT NULL PRIMARY KEY,
    `nome`             VARCHAR(40)  NOT NULL,
    `cognome`          VARCHAR(30)  NOT NULL,
    `email`            VARCHAR(30)  NOT NULL,
	`telefono`         BIGINT       NOT NULL,
    `indirizzo`        VARCHAR(40)  NOT NULL,
    `sesso`            CHAR         NOT NULL CHECK (sesso = 'M' OR sesso = 'F'),
    `stato`            TINYINT      NOT NULL CHECK (stato = 0 OR stato = 1)
)  
ENGINE=INNODB DEFAULT CHARSET=UTF8MB4;

CREATE TABLE IF NOT EXISTS `Biblioteca`.`Volontario` (
    `matricola`    BIGINT        NOT NULL PRIMARY KEY,
    `nome`         VARCHAR(40)   NOT NULL,
    `cognome`      VARCHAR(30)   NOT NULL,
    `email`        VARCHAR(30)       NULL DEFAULT NULL,
	`telefono`     BIGINT            NULL DEFAULT NULL,
    `indirizzo`    VARCHAR(30)   NOT NULL,
    `sesso`        CHAR          NOT NULL  CHECK (sesso = 'M' OR sesso = 'F')
)  
ENGINE=INNODB DEFAULT CHARSET=UTF8MB4;

CREATE TABLE IF NOT EXISTS `Biblioteca`.`Articolo` (
    `ID`         CHAR(4)       NOT NULL PRIMARY KEY,
    `nome`       VARCHAR(50)   NOT NULL,
    `stato`      VARCHAR(30)   NOT NULL CHECK (stato = 'in buone condizioni' 
                                             OR stato = 'in pessime condizioni' 
                                             OR stato = 'evidenziato/sottolineato'),
    `autore`     VARCHAR(40)       NULL DEFAULT NULL,
    `volume`     INT               NULL DEFAULT NULL,
    `categoria`  VARCHAR(35)   NOT NULL,
    `genere`     VARCHAR(35)   NOT NULL
) 
ENGINE=INNODB DEFAULT CHARSET=UTF8MB4;

CREATE TABLE IF NOT EXISTS `Biblioteca`.`Evento`(
	`data`                DATE          NOT NULL PRIMARY KEY,
    `nome`                VARCHAR(50)   NOT NULL, 
    `tipo`                VARCHAR(40)   NOT NULL, 
    `spettatori`          INT           NOT NULL, 
    `descrizione`         VARCHAR(100)      NULL DEFAULT NULL, 
    `ospite`              VARCHAR(40)       NULL DEFAULT NULL, 
    `fama`                CHAR              NULL DEFAULT NULL CHECK(fama = 'N' 
                                                                 OR fama = 'I' 
                                                                 OR fama IS NULL),
    `id_organizzatore`    BIGINT       NOT NULL,
    `id_presentatore`     BIGINT           NULL DEFAULT NULL, 
    `nome_presentatore`   VARCHAR(80)      NULL DEFAULT NULL, 
    
    CONSTRAINT `id_organizzatore`   
	    FOREIGN KEY (`id_organizzatore`)
		REFERENCES `Biblioteca`.`Volontario`(matricola)
        ON DELETE NO ACTION  
        ON UPDATE NO ACTION,
	CONSTRAINT `id_presentatore` 
		FOREIGN KEY(`id_presentatore`) 
		REFERENCES `Biblioteca`.`Volontario`(matricola)
        ON DELETE SET NULL 
        ON UPDATE NO ACTION
) 
ENGINE = InnoDB DEFAULT CHARSET = UTF8MB4;

CREATE TABLE IF NOT EXISTS `Biblioteca`.`Prenotazione`(
	`ID`                  CHAR(5)   NOT NULL PRIMARY KEY,
    `data_richiesta`      DATE      NOT NULL, 
    `data_conferma`       DATE          NULL DEFAULT NULL,
    `recapito_cliente`    BIGINT    NOT NULL,
    `cf_cliente`          CHAR(16)  NOT NULL, 
    `id_volontario`       BIGINT    NOT NULL,
    `id_articolo`         CHAR(4)   NOT NULL,
    
    CONSTRAINT `cf_cliente_k` 
	    FOREIGN KEY (`cf_cliente`)
        REFERENCES `Biblioteca`.`Cliente` (codice_fiscale)
        ON DELETE NO ACTION 
        ON UPDATE NO ACTION,
    CONSTRAINT `id_articolo_k` 
	    FOREIGN KEY (`id_articolo`)
        REFERENCES `Biblioteca`.`Articolo` (ID)
        ON DELETE NO ACTION 
        ON UPDATE NO ACTION,
	CONSTRAINT `id_volontario_k` 
		FOREIGN KEY (`id_volontario`)
        REFERENCES `Biblioteca`.`Volontario`(matricola)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) 
ENGINE = InnoDB DEFAULT CHARSET = UTF8MB4;

CREATE TABLE IF NOT EXISTS `Biblioteca`.`Prestito` (
    `ID`                CHAR(5)      NOT NULL PRIMARY KEY,
    `data_rilascio`     DATE         NOT NULL,
    `data_restituzione` DATE             NULL DEFAULT NULL,
    `stato1_articolo`   VARCHAR(30)  NOT NULL CHECK (stato1_articolo = 'in buone condizioni' 
                                             OR stato1_articolo = 'in pessime condizioni' 
                                             OR stato1_articolo = 'evidenziato/sottolineato'),
    `stato2_articolo`   VARCHAR(30)      NULL DEFAULT NULL CHECK (stato2_articolo = 'in buone condizioni' 
															  OR stato2_articolo = 'in pessime condizioni' 
															  OR stato2_articolo = 'evidenziato/sottolineato'
                                                              OR stato2_articolo IS NULL),
    `id_articolo`       CHAR(4)      NOT NULL,
    `cf_cliente`        CHAR(16)     NOT NULL,
	`id_volontario`     BIGINT       NOT NULL,
     
    CONSTRAINT `cf_cliente` 
	    FOREIGN KEY (`cf_cliente`)
        REFERENCES `Biblioteca`.`Cliente` (codice_fiscale)
        ON DELETE NO ACTION 
        ON UPDATE NO ACTION,
    CONSTRAINT `id_articolo` 
	    FOREIGN KEY (`id_articolo`)
        REFERENCES `Biblioteca`.`Articolo` (ID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
	CONSTRAINT `id_volontario`
		FOREIGN KEY (`id_volontario`)
        REFERENCES `Biblioteca`.`Volontario`(matricola)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
)
ENGINE = INNODB DEFAULT CHARSET=UTF8MB4;


/* ---- Un cliente può prendere in prestito gli articoli solo singolarmente (quindi finché non restituisce un articolo non può prenderne un altro)  */

DELIMITER //
CREATE TRIGGER PrestitoUnicoCliente
BEFORE INSERT ON biblioteca.prestito
FOR EACH ROW
BEGIN
IF NEW.cf_cliente IN (
    SELECT cf_cliente
    FROM prestito
) THEN

    IF (SELECT data_restituzione
        FROM prestito
        WHERE cf_cliente = NEW.cf_cliente) IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cliente non ha restituito il prestito';
    END IF;
END IF;
END //
DELIMITER ;


/* ---- Un articolo può essere dato in prestito solo se l’articolo è disponibile (quindi è già stato restituito) */
DELIMITER //
CREATE TRIGGER ArticoloPrestato
BEFORE INSERT ON biblioteca.prestito
FOR EACH ROW
BEGIN
	IF NEW.id_articolo IN (
    SELECT id_articolo
    FROM prestito
) THEN

    IF (SELECT data_restituzione
        FROM prestito
        WHERE id_articolo = NEW.id_articolo) IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Articolo non è ancora stato restituito';
    END IF;
END IF;
END //
DELIMITER ;


/* --- I clienti devono attenersi a due regole pena l’esclusione dal servizio: restituire l’articolo entro e non oltre trenta giorni e conservarlo con cura (ovvero non deve essere "in pessime condizioni")*/
DELIMITER //
CREATE TRIGGER RegoleBiblioteca
AFTER UPDATE ON biblioteca.prestito
FOR EACH ROW
BEGIN
   IF NEW.stato2_articolo = 'in pessime condizioni' OR (NEW.data_restituzione - OLD.data_rilascio) > 30 THEN
		UPDATE biblioteca.cliente
        SET stato = 0
        WHERE codice_fiscale = NEW.cf_cliente;
   END IF;
END//
DELIMITER ;


/* --- Un articolo può essere prenotato solo se il suo stato non è “in pessime condizioni” */
DELIMITER //
CREATE TRIGGER PrenotazioneImpossibile
BEFORE INSERT ON biblioteca.prenotazione
FOR EACH ROW
BEGIN
	IF NEW.id_articolo IN (SELECT ID FROM biblioteca.articolo WHERE stato = 'in pessime condizioni') THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Errore: Impossibile prenotare questo articolo';
	END IF;
END //
DELIMITER ;


/* --- Un articolo deve cambiare stato se cambia lo stato finale dell’articolo di prestito*/
DELIMITER //
CREATE TRIGGER StatoArticolo
AFTER UPDATE ON biblioteca.prestito
FOR EACH ROW
BEGIN
    IF (NEW.stato2_articolo <> OLD.stato1_articolo) THEN
        UPDATE biblioteca.articolo
        SET stato = NEW.stato2_articolo
        WHERE ID = NEW.id_articolo;
    END IF;
END //
DELIMITER ;