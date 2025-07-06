// controllers/loan.controller.js
const Loan = require('../models/loan.model.js');
const LoanItem = require('../models/loanItem.model.js');
const sql = require('../config/db.js');

// Tạo loan và loanItem cùng lúc
exports.createLoanWithItem = async (req, res) => {
  const { user_id, loan_date, book_id, return_date } = req.body;

  if (!user_id || !loan_date || !book_id) {
    return res.status(400).send({ message: "Thiếu user_id, loan_date hoặc book_id!" });
  }

  const loanData = { user_id, loan_date };

  try {
    // 1. Kiểm tra user tồn tại
    const [userRows] = await sql.promise().query("SELECT id FROM user WHERE id = ?", [user_id]);
    if (!userRows.length) {
      return res.status(400).send({ message: `Người dùng với id ${user_id} không tồn tại.` });
    }

    // 2. Tạo loan
    const [loanResult] = await sql.promise().query("INSERT INTO loan SET ?", loanData);
    const loanId = loanResult.insertId;

    // 3. Gọi create LoanItem với logic kiểm tra đầy đủ
    const loanItemData = { loan_id: loanId, book_id, return_date: return_date || null };
    LoanItem.create(loanItemData, async (err, loanItem) => {
      if (err) {
        // Nếu lỗi -> xóa loan
        await sql.promise().query("DELETE FROM loan WHERE id = ?", [loanId]);

        const messages = {
          invalid_book: "Sách không tồn tại.",
          book_out_of_stock: "Sách đã hết.",
          already_borrowed: "Bạn đã mượn sách này và chưa trả."
        };

        return res.status(400).send({ message: messages[err.kind] || "Lỗi khi mượn sách." });
      }

      // ✅ Cập nhật tổng số lượt mượn
      try {
        await sql.promise().query(
          "UPDATE book SET total_borrowed = total_borrowed + 1 WHERE id = ?",
          [book_id]
        );
      } catch (updateErr) {
        console.error("Lỗi cập nhật total_borrowed:", updateErr);
        // Không cần return vì loan đã tạo thành công, chỉ log lỗi
      }

      res.status(201).send({
        message: "Tạo phiếu mượn và mượn sách thành công!",
        loan_id: loanId,
        loan_item: loanItem
      });
    });
  } catch (err) {
    console.error("Lỗi server:", err);
    return res.status(500).send({ message: "Lỗi máy chủ khi tạo phiếu mượn." });
  }
};

// Tạo mới phiếu mượn
exports.create = (req, res) => {
  if (!req.body || !req.body.user_id || !req.body.loan_date) {
    return res.status(400).send({ message: "User ID và ngày mượn là bắt buộc!" });
  }

  const loan = {
    user_id: req.body.user_id,
    loan_date: req.body.loan_date
  };  

  Loan.create(loan, (err, data) => {
    if (err) {
      if (err.kind === "invalid_user") {
        return res.status(400).send({ message: `Người dùng với id ${loan.user_id} không tồn tại.` });
      }
      return res.status(500).send({ message: err.message || "Không thể tạo phiếu mượn." });
    }
    res.status(201).send(data);
  });
};

// Lấy tất cả phiếu mượn theo người dùng
exports.findAllByUser = (req, res) => {
  const userId = req.user?.id; // assuming verifyToken set req.user
  if (!userId) {
    return res.status(401).send({ message: "Không tìm thấy thông tin người dùng." });
  }

  Loan.findAllByUser(userId, (err, data) => {
    if (err) {
      if (err.kind === "invalid_user") {
        return res.status(400).send({ message: `Người dùng với id ${userId} không tồn tại.` });
      }
      return res.status(500).send({ message: err.message || "Không thể lấy danh sách phiếu mượn." });
    }
    res.send(data);
  });
};

// Lấy một phiếu mượn theo ID
exports.findOne = (req, res) => {
  Loan.findById(req.params.id, (err, data) => {
    if (err) {
      if (err.kind === "not_found") {
        return res.status(404).send({ message: `Không tìm thấy phiếu mượn với id ${req.params.id}.` });
      }
      return res.status(500).send({ message: `Lỗi khi lấy phiếu mượn với id ${req.params.id}.` });
    }
    res.send(data);
  });
};

// Cập nhật phiếu mượn
exports.update = (req, res) => {
  if (!req.body || !req.body.user_id || !req.body.loan_date) {
    return res.status(400).send({ message: "User ID và ngày mượn là bắt buộc!" });
  }

  const updated = {
    user_id: req.body.user_id,
    loan_date: req.body.loan_date
  };

  Loan.updateById(req.params.id, updated, (err, data) => {
    if (err) {
      if (err.kind === "not_found") {
        return res.status(404).send({ message: `Không tìm thấy phiếu mượn với id ${req.params.id}.` });
      }
      if (err.kind === "invalid_user") {
        return res.status(400).send({ message: `Người dùng với id ${updated.user_id} không tồn tại.` });
      }
      return res.status(500).send({ message: `Lỗi khi cập nhật phiếu mượn với id ${req.params.id}.` });
    }
    res.send(data);
  });
};

// Xóa phiếu mượn
exports.delete = (req, res) => {
  const loanId = req.params.id;

  Loan.remove(loanId, (err, data) => {
    if (err) {
      if (err.kind === "not_found") {
        return res.status(404).send({ message: `Không tìm thấy phiếu mượn với id ${loanId}.` });
      }
      if (err.kind === "loan_has_unreturned_items") {
        return res.status(400).send({ message: `Phiếu mượn với id ${loanId} có sách chưa trả, không thể xóa.` });
      }
      return res.status(500).send({ message: `Không thể xóa phiếu mượn với id ${loanId}.` });
    }
    res.send({ message: "Xóa phiếu mượn thành công!" });
  });
};

// Trả sách
exports.returnBooks = (req, res) => {
  const loanId = req.params.id;

  sql.query("SELECT loan_date FROM loan WHERE id = ?", [loanId], (err, results) => {
    if (err) {
      return res.status(500).send({ message: "Lỗi khi truy vấn phiếu mượn." });
    }
    if (!results.length) {
      return res.status(404).send({ message: `Không tìm thấy phiếu mượn với id ${loanId}.` });
    }

    const loanDate = new Date(results[0].loan_date);
    const today = new Date();
    if (today <= loanDate) {
      return res.status(400).send({
        message: "Ngày trả phải sau ngày mượn.",
        loan_date: loanDate.toISOString().split('T')[0],
        return_date: today.toISOString().split('T')[0]
      });
    }

    const formattedReturnDate = today.toISOString().split('T')[0];

    sql.query(
      "UPDATE loan_item SET return_date = ? WHERE loan_id = ? AND return_date IS NULL",
      [formattedReturnDate, loanId],
      (err2, result) => {
        if (err2) {
          return res.status(500).send({ message: "Lỗi khi cập nhật ngày trả." });
        }
        if (result.affectedRows === 0) {
          return res.status(400).send({ message: "Không có sách nào chưa trả trong phiếu mượn này." });
        }

        const updateQuantityQuery = `
          UPDATE book 
          SET quantity = quantity + 1
          WHERE id IN (
            SELECT book_id FROM loan_item
            WHERE loan_id = ? AND return_date = ?
          )
        `;

        sql.query(updateQuantityQuery, [loanId, formattedReturnDate], (err3) => {
          if (err3) {
            return res.status(500).send({ message: "Lỗi khi cập nhật số lượng sách." });
          }

          res.send({
            message: "Trả sách thành công!",
            loan_id: loanId,
            return_date: formattedReturnDate
          });
        });
      }
    );
  });
};

// Lấy tất cả phiếu mượn (cho thủ thư)
exports.findAll = (req, res) => {
  Loan.getAll((err, data) => {
    if (err) {
      return res.status(500).send({ message: err.message || "Không thể lấy danh sách phiếu mượn." });
    }
    res.send(data);
  });
};

// Lấy chi tiết 1 phiếu mượn kèm danh sách sách mượn
exports.getLoanWithItems = (req, res) => {
  const loanId = req.params.id;

  Loan.getLoanWithItems(loanId, (err, rows) => {
    if (err) {
      if (err.kind === "not_found") {
        return res.status(404).send({ message: `Không tìm thấy phiếu mượn với id ${loanId}.` });
      }
      return res.status(500).send({ message: "Lỗi khi truy vấn chi tiết phiếu mượn." });
    }

    // Gom dữ liệu thành cấu trúc: { loan_id, loan_date, user_name, items: [...] }
    const { loan_id, loan_date, user_name } = rows[0];
    const items = rows.map(row => ({
      loan_item_id: row.loan_item_id,
      title: row.title,
      author: row.author,
      return_date: row.return_date
    }));

    res.send({ loan_id, loan_date, user_name, items });
  });
};
