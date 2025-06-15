-- Thêm user mẫu
INSERT INTO user (username, email, password) VALUES
  ('user1', 'user1@example.com', 'password1'),
  ('user2', 'user2@example.com', 'password2');

-- Thêm librarian mẫu
INSERT INTO librarian (username, email, password) VALUES
  ('librarian1', 'librarian1@example.com', 'password1'),
  ('librarian2', 'librarian2@example.com', 'password2');

-- Thêm category mẫu
INSERT INTO category (name) VALUES
  ('Khoa học'),
  ('Văn học'),
  ('Công nghệ');

-- Thêm book mẫu
INSERT INTO book (title, author) VALUES
  ('Sách Toán', 'Nguyễn Văn A'),
  ('Sách Văn', 'Trần Thị B'),
  ('Sách Lập trình', 'Lê Văn C');

-- Thêm loan mẫu
INSERT INTO loan (user_id, loan_date) VALUES
  (1, '2024-06-01'),
  (2, '2024-06-02');

-- Thêm loan_item mẫu
INSERT INTO loan_item (loan_id, book_id) VALUES
  (1, 1),
  (1, 2),
  (2, 3);