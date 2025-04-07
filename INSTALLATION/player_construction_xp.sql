CREATE TABLE IF NOT EXISTS `player_xp` (
  `identifier` VARCHAR(64) NOT NULL,
  `xp` INT NOT NULL DEFAULT 0,
  `level` INT NOT NULL DEFAULT 1,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
