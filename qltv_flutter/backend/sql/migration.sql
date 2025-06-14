CREATE TABLE user (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(255) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL
);

CREATE TABLE librarian (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(255) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL
);

CREATE TABLE book (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  author VARCHAR(255)
);

CREATE TABLE loan (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  loan_date DATE NOT NULL,
  FOREIGN KEY (user_id) REFERENCES user(id)
);

CREATE TABLE loan_item (
  id INT AUTO_INCREMENT PRIMARY KEY,
  loan_id INT NOT NULL,
  book_id INT NOT NULL,
  FOREIGN KEY (loan_id) REFERENCES loan(id),
  FOREIGN KEY (book_id) REFERENCES book(id)
);

CREATE TABLE category (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
);


