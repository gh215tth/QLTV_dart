// controllers/user.controller.js
const jwt = require('jsonwebtoken');
const User = require('../models/user.model.js');
const db = require('../config/db.js');

// Create and Save a new User
exports.create = (req, res) => {
  if (!req.body) {
    return res.status(400).send({ message: "Content can not be empty!" });
  }

  const user = new User({
    username: req.body.username,
    email: req.body.email,
    password: req.body.password,
    role: 'user'
  });

  User.create(user, (err, data) => {
    if (err)
      return res.status(500).send({
        message: err.message || "Some error occurred while creating the User."
      });
    res.status(201).send(data);
  });
};

// Retrieve all Users
exports.findAll = (req, res) => {
  User.getAll((err, data) => {
    if (err)
      return res.status(500).send({
        message: err.message || "Some error occurred while retrieving users."
      });
    res.send(data);
  });
};

// Find a single User with ID
exports.findOne = (req, res) => {
  User.findById(req.params.userId, (err, data) => {
    if (err) {
      if (err.kind === "not_found") {
        return res.status(404).send({ message: `Not found User with id ${req.params.userId}.` });
      }
      return res.status(500).send({ message: "Error retrieving User with id " + req.params.userId });
    }
    res.send(data);
  });
};

// Update a User by ID
exports.update = (req, res) => {
  if (!req.body) {
    return res.status(400).send({ message: "Content can not be empty!" });
  }

  User.updateById(req.params.userId, new User(req.body), (err, data) => {
    if (err) {
      if (err.kind === "not_found") {
        return res.status(404).send({ message: `Not found User with id ${req.params.userId}.` });
      }
      return res.status(500).send({ message: "Error updating User with id " + req.params.userId });
    }
    res.send(data);
  });
};

// Delete a User by ID
exports.delete = (req, res) => {
  User.remove(req.params.userId, (err, data) => {
    if (err) {
      if (err.kind === "not_found") {
        return res.status(404).send({ message: `Not found User with id ${req.params.userId}.` });
      }
      return res.status(500).send({ message: "Could not delete User with id " + req.params.userId });
    }
    res.send({ message: "User was deleted successfully!" });
  });
};

// User login
exports.login = (req, res) => {
  const { username, password } = req.body;
  if (!username || !password)
    return res.status(400).json({ message: "Username and password are required!" });

  User.login(username, password, (err, user) => {
    if (err) {
      if (err.kind === "invalid_credentials") {
        return res.status(401).json({ message: "Invalid username or password!" });
      }
      return res.status(500).json({ message: err.message || "Login failed." });
    }

    const token = jwt.sign(
      { id: user.id, role: "user" },
      process.env.JWT_SECRET,
      { expiresIn: "24h" }
    );

    res.json({
      message: "Login successful!",
      user: { ...user, role: "user" },
      accessToken: token
    });
  });
};

// Lấy danh sách book_id user đang mượn mà chưa trả
exports.getBorrowedBookIds = (req, res) => {
  const userId = req.params.userId;

  const sql = `
    SELECT DISTINCT li.book_id
    FROM loan_item li
    JOIN loan l ON li.loan_id = l.id
    WHERE l.user_id = ? AND li.return_date IS NULL
  `;

  db.query(sql, [userId], (err, results) => {
    if (err) {
      console.error("Error fetching borrowed books:", err);
      return res.status(500).json({ message: "Lỗi server khi lấy sách chưa trả." });
    }

    const bookIds = results.map(row => row.book_id);
    res.json(bookIds);
  });
};

// Lấy thông tin user hiện tại
exports.getMe = (req, res) => {
  console.log('[DEBUG] Token decoded user:', req.user);
  const userId = req.user.id;
  User.findById(userId, (err, user) => {
    if (err) {
      if (err.kind === "not_found") {
        return res.status(404).json({ message: "Không tìm thấy người dùng." });
      }
      return res.status(500).json({ message: "Lỗi server khi lấy thông tin người dùng." });
    }
    res.json(user);
  });
};

// Cập nhật thông tin user hiện tại
exports.updateMe = (req, res) => {
  const userId = req.user.id;
  const updatedData = req.body;

  User.updateById(userId, new User(updatedData), (err, data) => {
    if (err) {
      if (err.kind === "not_found") {
        return res.status(404).json({ message: "Không tìm thấy người dùng." });
      }
      return res.status(500).json({ message: "Lỗi khi cập nhật thông tin người dùng." });
    }
    res.json(data);
  });
};
