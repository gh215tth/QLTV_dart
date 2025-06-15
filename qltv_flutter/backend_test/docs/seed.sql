-- seed.sql
-- Seed categories
INSERT INTO category (name) VALUES
  ('Lập trình'),
  ('Kinh tế'),
  ('Văn học');

-- Seed regular users
INSERT INTO users (username, email, password) VALUES
  ('alice', 'alice@mail.com', '$2b$10$hash_for_alice');

-- Seed librarians
INSERT INTO librarians (username, email, password) VALUES
  ('admin', 'admin@mail.com', '$2b$10$hash_for_admin');

-- Seed books
INSERT INTO books (title, author, publisher, year, quantity, available) VALUES
  ('Lập trình Python', 'Nguyễn Văn A', 'NXB Trẻ', 2021, 5, 5),
  ('Marketing Căn bản', 'Trần Văn B', 'NXB Kinh tế', 2020, 3, 3);