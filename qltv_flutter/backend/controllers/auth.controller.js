// controller/auth.controller.js
const User = require('../models/user.model.js');
const jwt = require('jsonwebtoken');
const config = require('../config/auth.config.js');

// Register a new user
exports.register = (req, res) => {
  // Validate request
  if (!req.body) {
    res.status(400).send({
      message: "Content can not be empty!"
    });
    return;
  }

  if (!req.body.username || !req.body.email || !req.body.password) {
    res.status(400).send({
      message: "Username, email, and password are required!"
    });
    return;
  }

  // Create a User
  const user = new User({
    username: req.body.username,
    email: req.body.email,
    password: req.body.password
  });

  // Save User in the database
  User.register(user, (err, data) => {
    if (err) {
      if (err.kind === "duplicate_username") {
        res.status(409).send({
          message: "Username already exists!"
        });
        return;
      } else if (err.kind === "duplicate_email") {
        res.status(409).send({
          message: "Email already exists!"
        });
        return;
      } else {
        res.status(500).send({
          message: err.message || "Some error occurred while registering the user."
        });
        return;
      }
    }

    // Generate token
    const token = jwt.sign({ id: data.id }, config.secret, {
      expiresIn: 86400 // 24 hours
    });

    res.status(201).send({
      message: "User registered successfully!",
      user: data,
      accessToken: token
    });
  });
};

// Login user
exports.login = (req, res) => {
  // Validate request
  if (!req.body) {
    res.status(400).send({
      message: "Content can not be empty!"
    });
    return;
  }

  if (!req.body.username || !req.body.password) {
    res.status(400).send({
      message: "Username and password are required!"
    });
    return;
  }

  // Login user
  User.login(req.body.username, req.body.password, (err, data) => {
    if (err) {
      if (err.kind === "invalid_credentials") {
        res.status(401).send({
          message: "Invalid username or password!"
        });
        return;
      } else {
        res.status(500).send({
          message: err.message || "Some error occurred while logging in."
        });
        return;
      }
    }

    // Generate token
    const token = jwt.sign({ id: data.id }, config.secret, {
      expiresIn: 86400 // 24 hours
    });

    res.status(200).send({
      message: "Login successful!",
      user: data,
      accessToken: token
    });
  });
};