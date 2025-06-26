// controller/librarian.controller.js
const jwt = require('jsonwebtoken');
const Librarian = require('../models/librarian.model.js');

// Create and save a new Librarian
exports.create = (req, res) => {
  if (!req.body) return res.status(400).send({ message: "Content can not be empty!" });

  const lib = new Librarian({
    username: req.body.username,
    email:    req.body.email,
    password: req.body.password
  });

  Librarian.create(lib, (err, data) => {
    if (err) {
      if (err.kind === "duplicate_username")
        return res.status(409).send({ message: "Username already exists!" });
      if (err.kind === "duplicate_email")
        return res.status(409).send({ message: "Email already exists!" });
      return res.status(500).send({ message: err.message || "Some error occurred while creating the librarian." });
    }
    res.status(201).send(data);
  });
};

// Retrieve all Librarians
exports.findAll = (req, res) => {
  Librarian.getAll((err, data) => {
    if (err) return res.status(500).send({ message: err.message || "Some error occurred while retrieving librarians." });
    res.send(data);
  });
};

// Find a single Librarian by ID
exports.findOne = (req, res) => {
  const id = req.params.id; // ✅ Sửa ở đây
  Librarian.findById(id, (err, data) => {
    if (err) {
      if (err.kind === "not_found")
        return res.status(404).send({ message: `Not found librarian with id ${id}.` });
      return res.status(500).send({ message: "Error retrieving librarian with id " + id });
    }
    res.send(data);
  });
};

// Update a Librarian by ID
exports.update = (req, res) => {
  if (!req.body) return res.status(400).send({ message: "Content can not be empty!" });

  const id = req.params.id; // ✅ Sửa ở đây
  const lib = new Librarian(req.body);
  Librarian.updateById(id, lib, (err, data) => {
    if (err) {
      if (err.kind === "not_found")
        return res.status(404).send({ message: `Not found librarian with id ${id}.` });
      return res.status(500).send({ message: "Error updating librarian with id " + id });
    }
    res.send(data);
  });
};

// Delete a Librarian by ID
exports.delete = (req, res) => {
  const id = req.params.id; // ✅ Sửa ở đây
  Librarian.remove(id, (err, data) => {
    if (err) {
      if (err.kind === "not_found")
        return res.status(404).send({ message: `Not found librarian with id ${id}.` });
      return res.status(500).send({ message: "Could not delete librarian with id " + id });
    }
    res.send({ message: "Librarian was deleted successfully!" });
  });
};

// Login librarian
exports.login = (req, res) => {
  const { username, password } = req.body;
  if (!username || !password)
    return res.status(400).json({ message: "Username and password are required!" });

  Librarian.login(username, password, (err, librarian) => {
    if (err) {
        console.log("LOGIN ERROR:", err);
        if (err.kind === "invalid_credentials")
            return res.status(401).json({ message: "Invalid username or password!" });
      return res.status(500).json({ message: err.message || "Login failed." });
    }

    // Tạo JWT token
    const token = jwt.sign(
      { id: librarian.id, role: "librarian" },
      process.env.JWT_SECRET,
      { expiresIn: "24h" }
    );

    res.json({
      message: "Login successful!",
      librarian,
      accessToken: token
    });
  });
};
