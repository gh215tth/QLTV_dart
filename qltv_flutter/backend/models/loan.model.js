// models/loan.model.js
const sql = require('../config/db.js');

const Loan = function(l) {
  this.user_id  = l.user_id;
  this.loan_date = l.loan_date;
};

Loan.create = (newLoan, result) => {
  // Kiểm tra user_id tồn tại
  sql.query("SELECT id FROM user WHERE id = ?", [newLoan.user_id], (err, res) => {
    if (err) return result(err, null);
    if (!res.length) return result({ kind: "invalid_user" }, null);
    
    sql.query(
      "INSERT INTO loan SET ?",
      newLoan,
      (err, res) => {
        if (err) return result(err, null);
        result(null, { id: res.insertId, ...newLoan });
      }
    );
  });
};

Loan.findById = (id, result) => {
  sql.query(
    "SELECT * FROM loan WHERE id = ?",
    [id],
    (err, res) => {
      if (err) return result(err, null);
      if (!res.length) return result({ kind: "not_found" }, null);
      result(null, res[0]);
    }
  );
};

Loan.findAllByUser = (userId, result) => {
  // Kiểm tra user_id tồn tại
  sql.query("SELECT id FROM user WHERE id = ?", [userId], (err, res) => {
    if (err) return result(err, null);
    if (!res.length) return result({ kind: "invalid_user" }, null);
    
    const sqlQuery = `
      SELECT 
        l.id,
        l.loan_date,
        li.return_date,
        b.title
      FROM loan l
      JOIN loan_item li ON l.id = li.loan_id
      JOIN book b ON li.book_id = b.id
      WHERE l.user_id = ?
      ORDER BY l.loan_date DESC
    `;
    
    sql.query(sqlQuery, [userId], (err, res) => {
      if (err) return result(err, null);
      result(null, res);
    });
  });
};

Loan.updateById = (id, data, result) => {
  // Kiểm tra user_id tồn tại
  sql.query("SELECT id FROM user WHERE id = ?", [data.user_id], (err, res) => {
    if (err) return result(err, null);
    if (!res.length) return result({ kind: "invalid_user" }, null);
    
    sql.query(
      "UPDATE loan SET user_id = ?, loan_date = ? WHERE id = ?",
      [data.user_id, data.loan_date, id],
      (err, res) => {
        if (err) return result(err, null);
        if (res.affectedRows === 0) return result({ kind: "not_found" }, null);
        result(null, { id, ...data });
      }
    );
  });
};

Loan.remove = (id, result) => {
  // Kiểm tra còn sách chưa trả
  sql.query("SELECT COUNT(*) as count FROM loan_item WHERE loan_id = ? AND return_date IS NULL", [id], (err, res) => {
    if (err) return result(err, null);
    if (res[0].count > 0) return result({ kind: "loan_has_unreturned_items" }, null);

    // Không cần xoá loan_item → MySQL tự lo
    sql.query("DELETE FROM loan WHERE id = ?", [id], (err2, res2) => {
      if (err2) return result(err2, null);
      if (res2.affectedRows === 0) return result({ kind: "not_found" }, null);
      result(null, res2);
    });
  });
};

Loan.getAll = result => {
  const query = `
    SELECT 
      l.id, l.loan_date, u.username,
      CASE 
        WHEN COUNT(li.id) = SUM(CASE WHEN li.return_date IS NOT NULL THEN 1 ELSE 0 END)
        THEN 'Đã trả'
        ELSE 'Chưa trả'
      END AS status
    FROM loan l
    JOIN user u ON l.user_id = u.id
    LEFT JOIN loan_item li ON l.id = li.loan_id
    GROUP BY l.id
    ORDER BY l.loan_date DESC
  `;

  sql.query(query, (err, res) => {
    if (err) return result(err, null);
    result(null, res);
  });
};

Loan.getLoanWithItems = (loanId, result) => {
  const query = `
    SELECT 
      l.id as loan_id,
      l.loan_date,
      u.username as user_name,
      li.id as loan_item_id,
      b.title,
      b.author,
      li.return_date
    FROM loan l
    JOIN user u ON l.user_id = u.id
    JOIN loan_item li ON l.id = li.loan_id
    JOIN book b ON li.book_id = b.id
    WHERE l.id = ?
  `;
  sql.query(query, [loanId], (err, res) => {
    if (err) return result(err, null);
    if (!res.length) return result({ kind: "not_found" }, null);
    result(null, res);
  });
};

module.exports = Loan;