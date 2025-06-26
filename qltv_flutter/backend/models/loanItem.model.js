// models/loanItem.model.js
const sql = require('../config/db.js');

const LoanItem = function (li) {
  this.loan_id = li.loan_id;
  this.book_id = li.book_id;
  this.return_date = li.return_date || null;
};

LoanItem.create = (newItem, result) => {
  sql.query("SELECT user_id FROM loan WHERE id = ?", [newItem.loan_id], (err, loanRes) => {
    if (err) return result(err, null);
    if (!loanRes.length) return result({ kind: "invalid_loan" }, null);

    const userId = loanRes[0].user_id;

    sql.query("SELECT id, quantity FROM book WHERE id = ?", [newItem.book_id], (err, bookRes) => {
      if (err) return result(err, null);
      if (!bookRes.length) return result({ kind: "invalid_book" }, null);
      if (bookRes[0].quantity <= 0) return result({ kind: "book_out_of_stock" }, null);

      const checkQuery = `
        SELECT li.id FROM loan_item li
        JOIN loan l ON li.loan_id = l.id
        WHERE l.user_id = ? AND li.book_id = ? AND li.return_date IS NULL
      `;
      sql.query(checkQuery, [userId, newItem.book_id], (err, checkRes) => {
        if (err) return result(err, null);
        if (checkRes.length > 0) return result({ kind: "already_borrowed" }, null);

        sql.query("INSERT INTO loan_item SET ?", newItem, (err, res) => {
          if (err) return result(err, null);

          // Tối ưu cập nhật quantity: chỉ cần giảm 1
          sql.query(
            "UPDATE book SET quantity = quantity - 1 WHERE id = ?",
            [newItem.book_id],
            (err2) => {
              if (err2) return result(err2, null);
              result(null, { id: res.insertId, ...newItem });
            }
          );
        });
      });
    });
  });
};


LoanItem.findById = (id, result) => {
  sql.query("SELECT * FROM loan_item WHERE id = ?", [id], (err, res) => {
    if (err) return result(err, null);
    if (!res.length) return result({ kind: "not_found" }, null);
    result(null, res[0]);
  });
};

LoanItem.getAll = result => {
  sql.query("SELECT * FROM loan_item", (err, res) => {
    if (err) return result(err, null);
    result(null, res);
  });
};

LoanItem.updateById = (id, data, result) => {
  sql.query("SELECT * FROM loan_item WHERE id = ?", [id], (err, res) => {
    if (err) return result(err, null);
    if (!res.length) return result({ kind: "not_found" }, null);

    const oldItem = res[0];

    // Không cho cập nhật loan_id
    if (data.loan_id && data.loan_id !== oldItem.loan_id) {
      return result({ kind: "invalid_update_loan_id" }, null);
    }

    // Kiểm tra book mới
    sql.query("SELECT id FROM book WHERE id = ?", [data.book_id], (err, bookRes) => {
      if (err) return result(err, null);
      if (!bookRes.length) return result({ kind: "invalid_book" }, null);

      const updates = {
        book_id: data.book_id,
        return_date: data.return_date || null
      };

      sql.query(
        "UPDATE loan_item SET book_id = ?, return_date = ? WHERE id = ?",
        [updates.book_id, updates.return_date, id],
        (err2, res2) => {
          if (err2) return result(err2, null);
          if (res2.affectedRows === 0) return result({ kind: "not_found" }, null);

          const quantityChanges = new Map();

          // Nếu đổi sách
          if (oldItem.book_id !== updates.book_id) {
            // Trả sách cũ
            quantityChanges.set(oldItem.book_id, (quantityChanges.get(oldItem.book_id) || 0) + 1);
            // Mượn sách mới
            quantityChanges.set(updates.book_id, (quantityChanges.get(updates.book_id) || 0) - 1);
          }

          // Nếu trước đó chưa trả, giờ trả → tăng sách
          if (!oldItem.return_date && updates.return_date) {
            quantityChanges.set(updates.book_id, (quantityChanges.get(updates.book_id) || 0) + 1);
          }

          const tasks = [];
          for (const [bookId, delta] of quantityChanges.entries()) {
            if (delta !== 0) {
              tasks.push(new Promise((resolve, reject) => {
                sql.query(
                  "UPDATE book SET quantity = quantity + ? WHERE id = ?",
                  [delta, bookId],
                  (err3) => err3 ? reject(err3) : resolve()
                );
              }));
            }
          }

          Promise.all(tasks)
            .then(() => result(null, { id, loan_id: oldItem.loan_id, ...updates }))
            .catch(error => result(error, null));
        }
      );
    });
  });
};

LoanItem.remove = (id, result) => {
  sql.query("SELECT book_id, return_date FROM loan_item WHERE id = ?", [id], (err, res) => {
    if (err) return result(err, null);
    if (!res.length) return result({ kind: "not_found" }, null);

    const { book_id, return_date } = res[0];
    const quantityChanges = new Map();

    // Nếu chưa trả sách → cần tăng lại
    if (!return_date) {
      quantityChanges.set(book_id, 1);
    }

    sql.query("DELETE FROM loan_item WHERE id = ?", [id], (err2, res2) => {
      if (err2) return result(err2, null);
      if (res2.affectedRows === 0) return result({ kind: "not_found" }, null);

      // Thực hiện update quantity nếu cần
      const tasks = [];
      for (const [bookId, delta] of quantityChanges.entries()) {
        tasks.push(new Promise((resolve, reject) => {
          sql.query(
            "UPDATE book SET quantity = quantity + ? WHERE id = ?",
            [delta, bookId],
            (err3) => err3 ? reject(err3) : resolve()
          );
        }));
      }

      Promise.all(tasks)
        .then(() => result(null, res2))
        .catch(error => result(error, null));
    });
  });
};

LoanItem.findByLoanId = (loanId, result) => {
  sql.query("SELECT * FROM loan_item WHERE loan_id = ?", [loanId], (err, res) => {
    if (err) return result(err, null);
    if (res.length) return result(null, res);
    return result({ kind: "not_found" }, null);
  });
};
// Kiểm tra loan_id và book_id tồn tại

module.exports = LoanItem;