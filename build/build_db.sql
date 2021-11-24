USE tnlooker_db;

CREATE TABLE numbers
(
    id INT AUTO_INCREMENT PRIMARY KEY NOT NULL,
    number VARCHAR(20), 
    local_format VARCHAR(20),
    int_format VARCHAR(20),
    country_prefix VARCHAR(10),
    country_code VARCHAR(2),
    country_name VARCHAR(100),
    location VARCHAR(100),
    carrier VARCHAR(100),
    line_type VARCHAR(50),
    valid BOOLEAN,
  	updated_on TIMESTAMP DEFAULT NOW() ON UPDATE NOW()
);

