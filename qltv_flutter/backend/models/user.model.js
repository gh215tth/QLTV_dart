// models/user.model.js
const sql = require('../config/db.js');
const bcrypt = require('bcryptjs');

const User = function(user) {
  this.username = user.username;
  this.email = user.email;
  this.password = user.password;
  this.role = user.role || 'user'; // default
};

// Create a new User
User.create = async (newUser, result) => {
  try {
    const salt = await bcrypt.genSalt(10);
    newUser.password = await bcrypt.hash(newUser.password, salt);

    // Kiểm tra username hoặc email đã tồn tại
    sql.query(
      "SELECT * FROM user WHERE username = ? OR email = ?",
      [newUser.username, newUser.email],
      (err, res) => {
        if (err) {
          console.log("error: ", err);
          result(err, null);
          return;
        }

        if (res.length > 0) {
          if (res.some(u => u.username === newUser.username)) {
            result({ kind: "duplicate_username" }, null);
            return;
          }
          if (res.some(u => u.email === newUser.email)) {
            result({ kind: "duplicate_email" }, null);
            return;
          }
        }

        sql.query("INSERT INTO user SET ?", newUser, (err, res) => {
          if (err) {
            console.log("error: ", err);
            result(err, null);
            return;
          }

          const { password, ...userWithoutPassword } = newUser;
          result(null, { id: res.insertId, ...userWithoutPassword });
        });
      }
    );
  } catch (error) {
    console.log("hash error: ", error);
    result(error, null);
  }
};

// Login User
User.login = (username, password, result) => {
  sql.query("SELECT * FROM user WHERE username = ?", [username], async (err, res) => {
    if (err) {
      console.log("error: ", err);
      result(err, null);
      return;
    }

    if (res.length === 0) {
      result({ kind: "invalid_credentials" }, null);
      return;
    }

    const user = res[0];

    try {
      const isMatch = await bcrypt.compare(password, user.password);
      if (!isMatch) {
        result({ kind: "invalid_credentials" }, null);
        return;
      }

      const { password: _, ...userWithoutPassword } = user;
      result(null, userWithoutPassword);
    } catch (error) {
      result(error, null);
    }
  });
};

// Find a User by ID
User.findById = (id, result) => {
  sql.query(
    "SELECT id, username, email, role FROM user WHERE id = ?",
    [id],
    (err, res) => {
      if (err) {
        result(err, null);
        return;
      }

      if (res.length) {
        result(null, res[0]);
        return;
      }

      result({ kind: "not_found" }, null);
    }
  );
};

// Get all Users
User.getAll = result => {
  sql.query("SELECT id, username, email, role FROM user", (err, res) => {
    if (err) {
      result(null, err);
      return;
    }
    result(null, res);
  });
};

// Update a User
User.updateById = (id, user, result) => {
  const updateAndHash = async () => {
    try {
      if (user.password) {
        const salt = await bcrypt.genSalt(10);
        user.password = await bcrypt.hash(user.password, salt);
      }

      sql.query(
        "UPDATE user SET username = ?, email = ?, password = ?, role = ? WHERE id = ?",
        [user.username, user.email, user.password, user.role || 'user', id],
        (err, res) => {
          if (err) {
            result(null, err);
            return;
          }

          if (res.affectedRows === 0) {
            result({ kind: "not_found" }, null);
            return;
          }

          const { password, ...userWithoutPassword } = user;
          result(null, { id, ...userWithoutPassword });
        }
      );
    } catch (err) {
      result(err, null);
    }
  };

  updateAndHash();
};

// Delete User
User.remove = (id, result) => {
  sql.query("DELETE FROM user WHERE id = ?", [id], (err, res) => {
    if (err) {
      result(null, err);
      return;
    }

    if (res.affectedRows === 0) {
      result({ kind: "not_found" }, null);
      return;
    }

    result(null, res);
  });
};

module.exports = User;
