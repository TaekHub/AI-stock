CREATE DATABASE stock_trading;

USE stock_trading;

CREATE TABLE stock_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    date DATETIME NOT NULL,
    open_price FLOAT NOT NULL,
    high_price FLOAT NOT NULL,
    low_price FLOAT NOT NULL,
    close_price FLOAT NOT NULL,
    volume BIGINT NOT NULL
);
