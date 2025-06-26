// models/librarian.model.js
const sql = require('../config/db.js');
const bcrypt = require('bcryptjs');

const Librarian = function(l) {
  this.username = l.username;
  this.email    = l.email;
  this.password = l.password;
};

Librarian.create = async (newLibrarian, result) => {
  try {
    const salt = await bcrypt.genSalt(10);
    newLibrarian.password = await bcrypt.hash(newLibrarian.password, salt);

    sql.query(
      "SELECT * FROM librarian WHERE username = ? OR email = ?",
      [newLibrarian.username, newLibrarian.email],
      (err, res) => {
        if (err) return result(err, null);
        if (res.length) {
          if (res.some(u => u.username === newLibrarian.username))
            return result({ kind: "duplicate_username" }, null);
          if (res.some(u => u.email === newLibrarian.email))
            return result({ kind: "duplicate_email" }, null);
        }
        sql.query("INSERT INTO librarian SET ?", newLibrarian, (err, res) => {
          if (err) return result(err, null);
          const { password, ...rest } = newLibrarian;
          result(null, { id: res.insertId, ...rest });
        });
      }
    );
  } catch (e) {
    result(e, null);
  }
};

Librarian.findById = (id, result) => {
  sql.query("SELECT id, username, email FROM librarian WHERE id = ?", [id], (err, res) => {
    if (err) return result(err, null);
    if (!res.length) return result({ kind: "not_found" }, null);
    result(null, res[0]);
  });
};

Librarian.getAll = result => {
  sql.query("SELECT id, username, email FROM librarian", (err, res) => {
    if (err) return result(err, null);
    result(null, res);
  });
};

Librarian.updateById = (id, data, result) => {
  const update = () => {
    sql.query(
      "UPDATE librarian SET username = ?, email = ?, password = ? WHERE id = ?",
      [data.username, data.email, data.password, id],
      (err, res) => {
        if (err) return result(err, null);
        if (res.affectedRows === 0) return result({ kind: "not_found" }, null);
        const { password, ...rest } = data;
        result(null, { id, ...rest });
      }
    );
  };

  if (data.password && data.password.trim()) {
    bcrypt.hash(data.password, 10, (err, hash) => {
      if (err) return result(err, null);
      data.password = hash;
      update();
    });
  } else {
    // keep old password
    sql.query("SELECT password FROM librarian WHERE id = ?", [id], (err, res) => {
      if (err) return result(err, null);
      data.password = res[0].password;
      update();
    });
  }
};

Librarian.remove = (id, result) => {
  sql.query("DELETE FROM librarian WHERE id = ?", [id], (err, res) => {
    if (err) return result(err, null);
    if (res.affectedRows === 0) return result({ kind: "not_found" }, null);
    result(null, res);
  });
};

Librarian.login = (username, password, result) => {
  sql.query(
    "SELECT * FROM librarian WHERE username = ?",
    [username],
    async (err, res) => {
      if (err) return result(err, null);
      if (!res.length) return result({ kind: "invalid_credentials" }, null);

      const librarian = res[0];
      try {
        const isMatch = await bcrypt.compare(password, librarian.password);
        if (!isMatch) return result({ kind: "invalid_credentials" }, null);

        const { password: pw, ...libWithoutPassword } = librarian;
        result(null, libWithoutPassword);
      } catch (error) {
        result(error, null);
      }
    }
  );
};

module.exports = Librarian;
