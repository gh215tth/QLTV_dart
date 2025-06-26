const LoanItem = require('../models/loanItem.model.js');
const sql = require('../config/db.js'); // để dùng cho promise query

// Tạo mới một loan item
exports.create = (req, res) => {
  const loanId = req.body.loan_id;
  const bookId = req.body.book_id;
  const returnDate = req.body.return_date || null;

  if (!loanId || !bookId) {
    return res.status(400).send({ message: "Loan ID và Book ID là bắt buộc!" });
  }

  const item = { loan_id: loanId, book_id: bookId, return_date: returnDate };

  LoanItem.create(item, async (err, data) => {
    if (err) {
      const errorMessages = {
        invalid_loan: "Phiếu mượn không tồn tại.",
        invalid_book: "Sách không tồn tại.",
        book_out_of_stock: "Sách đã hết.",
        already_borrowed: "Bạn đã mượn sách này và chưa trả."
      };

      // Nếu lỗi thuộc nhóm cần xóa loan vừa tạo
      const cleanupErrors = ["invalid_book", "book_out_of_stock", "already_borrowed"];
      if (cleanupErrors.includes(err.kind)) {
        try {
          const [loanExists] = await sql.promise().query("SELECT id FROM loan WHERE id = ?", [loanId]);
          if (loanExists.length > 0) {
            await sql.promise().query("DELETE FROM loan WHERE id = ?", [loanId]);
          }
        } catch (cleanupErr) {
          console.error("Lỗi khi xóa loan rác:", cleanupErr);
        }
      }

      return res.status(400).send({
        message: errorMessages[err.kind] || "Lỗi khi tạo chi tiết mượn."
      });
    }

    res.status(201).send(data);
  });
};

// Lấy tất cả loan item
exports.findAll = (req, res) => {
  LoanItem.getAll((err, data) => {
    if (err) {
      return res.status(500).send({ message: err.message || "Không thể lấy danh sách chi tiết mượn." });
    }
    res.send(data);
  });
};

// Lấy loan item theo id
exports.findOne = (req, res) => {
  LoanItem.findById(req.params.id, (err, data) => {
    if (err) {
      if (err.kind === "not_found") {
        return res.status(404).send({ message: `Không tìm thấy chi tiết mượn với id ${req.params.id}.` });
      }
      return res.status(500).send({ message: `Lỗi khi lấy chi tiết mượn với id ${req.params.id}.` });
    }
    res.send(data);
  });
};

// Cập nhật loan item theo id
exports.update = (req, res) => {
  if (!req.body || !req.body.book_id) {
    return res.status(400).send({ message: "Book ID là bắt buộc!" });
  }

  // Không cho phép cập nhật loan_id
  if (req.body.loan_id !== undefined) {
    delete req.body.loan_id;
  }

  const data = {
    loan_id: req.body.loan_id,
    book_id: req.body.book_id,
    return_date: req.body.return_date || null
  };

  LoanItem.updateById(req.params.id, data, (err, updated) => {
    if (err) {
      if (err.kind === "not_found") {
        return res.status(404).send({ message: `Không tìm thấy chi tiết mượn với id ${req.params.id}.` });
      }
      if (err.kind === "invalid_loan") {
        return res.status(400).send({ message: `Phiếu mượn với id ${data.loan_id} không tồn tại.` });
      }
      if (err.kind === "invalid_book") {
        return res.status(400).send({ message: `Sách với id ${data.book_id} không tồn tại.` });
      }
      return res.status(500).send({ message: `Lỗi khi cập nhật chi tiết mượn với id ${req.params.id}.` });
    }
    res.send(updated);
  });
};

// Xóa loan item
exports.delete = (req, res) => {
  LoanItem.remove(req.params.id, (err, data) => {
    if (err) {
      if (err.kind === "not_found") {
        return res.status(404).send({ message: `Không tìm thấy chi tiết mượn với id ${req.params.id}.` });
      }
      return res.status(500).send({ message: `Không thể xóa chi tiết mượn với id ${req.params.id}.` });
    }
    res.send({ message: "Xóa chi tiết mượn thành công!" });
  });
};

// Lấy danh sách chi tiết phiếu mượn theo loan_id
exports.findByLoanId = (req, res) => {
  const loanId = req.params.loan_id;

  LoanItem.findByLoanId(loanId, (err, data) => {
    if (err) {
      if (err.kind === "not_found") {
        return res.status(404).send({ message: `Không tìm thấy chi tiết mượn với loan_id ${loanId}.` });
      }
      return res.status(500).send({ message: `Lỗi khi truy xuất chi tiết mượn với loan_id ${loanId}.` });
    }
    res.send(data);
  });
};
