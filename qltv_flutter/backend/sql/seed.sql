-- Thêm category mẫu
-- Dữ liệu cho bảng category
INSERT INTO category (name) VALUES
  ('Khoa học'),
  ('Văn học'),
  ('Lịch sử'),
  ('Công nghệ');

-- Dữ liệu cho bảng book
INSERT INTO book (title, author, category_id, status) VALUES
  ('Vũ trụ và vật lý hiện đại', 'Stephen Hawking', 1, 0),
  ('Những người khốn khổ', 'Victor Hugo', 2, 0),
  ('Lược sử loài người', 'Yuval Noah Harari', 3, 1),
  ('Lập trình Python cơ bản', 'Nguyễn Văn A', 4, 0),
  ('AI trong cuộc sống', 'Trần Thị B', 4, 1),
  ('Tâm lý học đám đông', 'Gustave Le Bon', 1, 0);

-- Dữ liệu cho bảng loan
-- Giả sử user_id = 1 và 2 đã tồn tại trong bảng user
INSERT INTO loan (user_id, loan_date) VALUES
  (1, '2024-05-01'),
  (2, '2024-06-10');

-- Dữ liệu cho bảng loan_item
-- Giả sử loan_id = 1 mượn sách id = 3, loan_id = 2 mượn sách id = 5
INSERT INTO loan_item (loan_id, book_id) VALUES
  (1, 3),
  (2, 5);
