mysql - uroot - ppassword --local-infile
SET GLOBAL local_infile = 1;
DROP TABLE IF EXISTS `test`.`test`;
CREATE TABLE IF NOT EXISTS `test` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `Type de media` VARCHAR(200),
    `Chaine /Station` VARCHAR(200),
    `Diffusion de la chaine` VARCHAR(200),
    `Annee` VARCHAR(200),
    `Heure` VARCHAR(200),
    `Taux d'expression des femmes` VARCHAR(200),
    `Heures prises en compte` VARCHAR(200),
    `Taux d'expression des hommes` VARCHAR(200),
    PRIMARY KEY (`id`)
);
