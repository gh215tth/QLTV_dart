// models/book.model.js
const sql = require('../config/db.js');

const Book = function(b) {
  this.title = b.title;
  this.author = b.author;
  this.category_id = b.category_id;
  this.quantity = b.quantity;
  this.total_borrowed = b.total_borrowed ?? 0;
};

Book.create = (newBook, result) => {
  // Kiểm tra category_id tồn tại
  sql.query("SELECT id FROM category WHERE id = ?", [newBook.category_id], (err, res) => {
    if (err) return result(err, null);
    if (!res.length) return result({ kind: "invalid_category" }, null);

    sql.query("INSERT INTO book SET ?", newBook, (err, res) => {
      if (err) return result(err, null);
      result(null, { id: res.insertId, ...newBook });
    });
  });
};

Book.findById = (id, result) => {
  sql.query(`
    SELECT b.*, c.name AS category_name 
    FROM book b 
    LEFT JOIN category c ON b.category_id = c.id 
    WHERE b.id = ?
  `, [id], (err, res) => {
    if (err) return result(err, null);
    if (!res.length) return result({ kind: "not_found" }, null);
    result(null, res[0]);
  });
};

Book.getAll = (search, result) => {
  if (search) {
    const q = `%${search}%`;
    sql.query(`
      SELECT b.*, c.name AS category_name 
      FROM book b 
      LEFT JOIN category c ON b.category_id = c.id 
      WHERE b.title LIKE ? OR b.author LIKE ?
    `, [q, q], (err, res) => {
      if (err) return result(err, null);
      result(null, res);
    });
  } else {
    sql.query(`
      SELECT b.*, c.name AS category_name 
      FROM book b 
      LEFT JOIN category c ON b.category_id = c.id
    `, (err, res) => {
      if (err) return result(err, null);
      result(null, res);
    });
  }
};

Book.findByCategoryId = (catId, result) => {
  // Kiểm tra category_id tồn tại
  sql.query("SELECT id FROM category WHERE id = ?", [catId], (err, res) => {
    if (err) return result(err, null);
    if (!res.length) return result({ kind: "invalid_category" }, null);

    sql.query(`
      SELECT b.*, c.name AS category_name 
      FROM book b
      LEFT JOIN category c ON b.category_id = c.id
      WHERE b.category_id = ?
    `, [catId], (err, res) => {
      if (err) return result(err, null);
      result(null, res);
    });
  });
};

Book.updateById = (id, data, result) => {
  const { title, author, category_id, quantity } = data;
  // Kiểm tra category_id tồn tại
  sql.query("SELECT id FROM category WHERE id = ?", [category_id], (err, res) => {
    if (err) return result(err, null);
    if (!res.length) return result({ kind: "invalid_category" }, null);

    sql.query(
      "UPDATE book SET title = ?, author = ?, category_id = ?, quantity = ? WHERE id = ?",
      [title, author, category_id, quantity, id],
      (err, res) => {
        if (err) return result(err, null);
        if (res.affectedRows === 0) return result({ kind: "not_found" }, null);
        result(null, { id, ...data });
      }
    );
  });
};

Book.remove = (id, result) => {
  // Kiểm tra xem sách có đang được mượn không
  sql.query("SELECT COUNT(*) as count FROM loan_item WHERE book_id = ? AND return_date IS NULL", [id], (err, res) => {
    if (err) return result(err, null);
    if (res[0].count > 0) return result({ kind: "book_in_use" }, null);

    sql.query("DELETE FROM book WHERE id = ?", [id], (err, res) => {
      if (err) return result(err, null);
      if (res.affectedRows === 0) return result({ kind: "not_found" }, null);
      result(null, res);
    });
  });
};

// Hàm tăng số lượt mượn
Book.increaseTotalBorrowed = (bookId, result) => {
  sql.query(
    "UPDATE book SET total_borrowed = total_borrowed + 1 WHERE id = ?",
    [bookId],
    (err, res) => {
      if (err) {
        console.error("❌ Lỗi tăng total_borrowed:", err);
        return result(err, null);
      }
      result(null, res);
    }
  );
};

// Lấy top sách được mượn nhiều nhất
Book.getTopBorrowed = (limit = 10, result) => {
  sql.query(
    "SELECT * FROM book WHERE total_borrowed > 0 ORDER BY total_borrowed DESC, id ASC LIMIT ?",
    [limit],
    (err, res) => {
      if (err) return result(err, null);
      result(null, res);
    }
  );
};

module.exports = Book;
