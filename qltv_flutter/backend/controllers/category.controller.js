// controllers/category.controller.js
const Category = require('../models/category.model.js');
const db = require('../config/db');

// Tạo mới danh mục
exports.create = (req, res) => {
  if (!req.body || !req.body.name) {
    return res.status(400).send({ message: "Tên danh mục là bắt buộc!" });
  }

  Category.create({ name: req.body.name }, (err, data) => {
    if (err) {
      return res.status(500).send({ message: err.message || "Không thể tạo danh mục." });
    }
    res.status(201).send(data);
  });
};

// Lấy tất cả danh mục
exports.findAll = (req, res) => {
  Category.getAll((err, data) => {
    if (err) {
      return res.status(500).send({ message: err.message || "Không thể lấy danh sách danh mục." });
    }
    res.send(data);
  });
};

// Lấy một danh mục theo ID
exports.findOne = (req, res) => {
  Category.findById(req.params.id, (err, data) => {
    if (err) {
      if (err.kind === "not_found") {
        return res.status(404).send({ message: `Không tìm thấy danh mục với id ${req.params.id}.` });
      }
      return res.status(500).send({ message: `Lỗi khi lấy danh mục với id ${req.params.id}.` });
    }
    res.send(data);
  });
};

// Cập nhật danh mục
exports.update = (req, res) => {
  if (!req.body || !req.body.name) {
    return res.status(400).send({ message: "Tên danh mục là bắt buộc!" });
  }

  Category.updateById(req.params.id, { name: req.body.name }, (err, data) => {
    if (err) {
      if (err.kind === "not_found") {
        return res.status(404).send({ message: `Không tìm thấy danh mục với id ${req.params.id}.` });
      }
      return res.status(500).send({ message: `Lỗi khi cập nhật danh mục với id ${req.params.id}.` });
    }
    res.send(data);
  });
};

// Xóa danh mục
exports.delete = (req, res) => {
  Category.remove(req.params.id, (err, data) => {
    if (err) {
      if (err.kind === "not_found") {
        return res.status(404).send({ message: `Không tìm thấy danh mục với id ${req.params.id}.` });
      }
      if (err.kind === "category_in_use") {
        return res.status(400).send({ message: `Danh mục với id ${req.params.id} đang được sử dụng, không thể xóa.` });
      }
      return res.status(500).send({ message: `Không thể xóa danh mục với id ${req.params.id}.` });
    }
    res.send({ message: "Xóa danh mục thành công!" });
  });
};

// Lấy danh sách sách theo ID danh mục (kèm quantity và trạng thái còn sách)
exports.getBooksByCategory = (req, res) => {
  const categoryId = parseInt(req.params.id, 10);
  if (isNaN(categoryId)) {
    return res.status(400).send({ message: "ID danh mục không hợp lệ." });
  }

  // Kiểm tra danh mục tồn tại
  Category.findById(categoryId, (err, category) => {
    if (err) {
      if (err.kind === "not_found") {
        return res.status(404).send({ message: `Không tìm thấy danh mục với id ${categoryId}.` });
      }
      return res.status(500).send({ message: `Lỗi khi kiểm tra danh mục với id ${categoryId}.` });
    }

    const query = `
      SELECT 
        b.id,
        b.title,
        b.author,
        b.category_id,
        b.quantity
      FROM book b
      WHERE b.category_id = ?
    `;

    db.query(query, [categoryId], (err, books) => {
      if (err) {
        return res.status(500).send({ message: "Lỗi khi truy xuất sách theo danh mục." });
      }

      const booksWithStatus = books.map(book => ({
        ...book,
        available: book.quantity > 0
      }));

      res.send(booksWithStatus);
    });
  });
};