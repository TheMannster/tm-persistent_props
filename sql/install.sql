CREATE TABLE IF NOT EXISTS `tm_persistent_props` (
    `id`         INT(11)       NOT NULL AUTO_INCREMENT,
    `owner_cid`  VARCHAR(64)   NOT NULL,
    `owner_name` VARCHAR(96)   DEFAULT NULL,
    `model`      VARCHAR(96)   NOT NULL,
    `x`          FLOAT         NOT NULL,
    `y`          FLOAT         NOT NULL,
    `z`          FLOAT         NOT NULL,
    `heading`    FLOAT         NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_owner` (`owner_cid`),
    KEY `idx_model` (`model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
