// controllers/book.controller.js
const Book = require('../models/book.model.js');

// Tạo mới sách
exports.create = (req, res) => {
  const { title, author, category_id, quantity } = req.body;
  if (!title || !category_id) {
    return res.status(400).send({ message: "Title và category_id là bắt buộc!" });
  }

  const book = {
    title,
    author,
    category_id,
    quantity: quantity ?? 1 // mặc định là 1 nếu không truyền vào
  };

  Book.create(book, (err, data) => {
    if (err) {
      if (err.kind === "invalid_category") {
        return res.status(400).send({ message: `Danh mục với id ${category_id} không tồn tại.` });
      }
      return res.status(500).send({ message: err.message || "Không thể tạo sách." });
    }
    res.status(201).send(data);
  });
};

// Lấy tất cả sách (có thể tìm kiếm)
exports.findAll = (req, res) => {
  const search = req.query.q; // ?q=keyword
  Book.getAll(search, (err, data) => {
    if (err) {
      return res.status(500).send({ message: err.message || "Không thể lấy danh sách sách." });
    }
    res.send(data);
  });
};

// Lấy sách theo danh mục
exports.findByCategory = (req, res) => {
  const catId = req.params.categoryId;
  Book.findByCategoryId(catId, (err, data) => {
    if (err) {
      if (err.kind === "invalid_category") {
        return res.status(400).send({ message: `Danh mục với id ${catId} không tồn tại.` });
      }
      return res.status(500).send({ message: err.message || "Không thể lấy sách theo danh mục." });
    }
    res.send(data);
  });
};

// Lấy một sách theo ID
exports.findOne = (req, res) => {
  Book.findById(req.params.bookId, (err, data) => {
    if (err) {
      if (err.kind === "not_found") {
        return res.status(404).send({ message: `Không tìm thấy sách với id ${req.params.bookId}.` });
      }
      return res.status(500).send({ message: `Lỗi khi lấy sách với id ${req.params.bookId}.` });
    }
    res.send(data);
  });
};

// Cập nhật sách
exports.update = (req, res) => {
  const { title, author, category_id, quantity } = req.body;
  if (!title || !category_id) {
    return res.status(400).send({ message: "Title và category_id là bắt buộc!" });
  }

  const book = { title, author, category_id, quantity };
  Book.updateById(req.params.bookId, book, (err, data) => {
    if (err) {
      if (err.kind === "not_found") {
        return res.status(404).send({ message: `Không tìm thấy sách với id ${req.params.bookId}.` });
      }
      if (err.kind === "invalid_category") {
        return res.status(400).send({ message: `Danh mục với id ${category_id} không tồn tại.` });
      }
      return res.status(500).send({ message: `Lỗi khi cập nhật sách với id ${req.params.bookId}.` });
    }
    res.send(data);
  });
};

// Xóa sách
exports.delete = (req, res) => {
  Book.remove(req.params.bookId, (err, _) => {
    if (err) {
      if (err.kind === "not_found") {
        return res.status(404).send({ message: `Không tìm thấy sách với id ${req.params.bookId}.` });
      }
      if (err.kind === "book_in_use") {
        return res.status(400).send({ message: `Sách với id ${req.params.bookId} đang được mượn, không thể xóa.` });
      }
      return res.status(500).send({ message: `Không thể xóa sách với id ${req.params.bookId}.` });
    }
    res.send({ message: "Xóa sách thành công!" });
  });
};