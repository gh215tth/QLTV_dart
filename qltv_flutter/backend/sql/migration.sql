-- sql/migration.sql

-- Tạo bảng danh mục sách
CREATE TABLE category (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
);

-- Tạo bảng người dùng
CREATE TABLE user (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(255) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
);

-- Tạo bảng thủ thư
CREATE TABLE librarian (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(255) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL
);

-- Tạo bảng sách
CREATE TABLE book (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  author VARCHAR(255),
  category_id INT NOT NULL,
  quantity INT NOT NULL DEFAULT 0,
  FOREIGN KEY (category_id) REFERENCES category(id)
);

-- Tạo bảng phiếu mượn
CREATE TABLE loan (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  loan_date DATE NOT NULL,
  FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE
);

-- Tạo bảng chi tiết mượn sách
CREATE TABLE loan_item (
  id INT AUTO_INCREMENT PRIMARY KEY,
  loan_id INT NOT NULL,
  book_id INT NOT NULL,
  return_date DATE DEFAULT NULL,
  FOREIGN KEY (loan_id) REFERENCES loan(id) ON DELETE CASCADE,
  FOREIGN KEY (book_id) REFERENCES book(id)
);

ALTER TABLE user
ADD COLUMN role ENUM('user', 'librarian') NOT NULL DEFAULT 'user';

ALTER TABLE book ADD COLUMN total_borrowed INT DEFAULT 0;