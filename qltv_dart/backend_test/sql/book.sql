CREATE TABLE books (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  author VARCHAR(255),
  category_id INT,
  quantity INT NOT NULL DEFAULT 1,
  FOREIGN KEY (category_id) REFERENCES categories(id)
);