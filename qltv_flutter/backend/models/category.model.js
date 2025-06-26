// models/category.model.js
const sql = require('../config/db.js');

const Category = function(c) {
  this.name = c.name;
};

Category.create = (newCat, result) => {
  sql.query("INSERT INTO category SET ?", newCat, (err, res) => {
    if (err) return result(err, null);
    result(null, { id: res.insertId, ...newCat });
  });
};

Category.findById = (id, result) => {
  sql.query(
    "SELECT * FROM category WHERE id = ?",
    [id],
    (err, res) => {
      if (err) return result(err, null);
      if (!res.length) return result({ kind: "not_found" }, null);
      result(null, res[0]);
    }
  );
};

Category.getAll = result => {
  sql.query("SELECT * FROM category", (err, res) => {
    if (err) return result(err, null);
    result(null, res);
  });
};

Category.updateById = (id, data, result) => {
  sql.query(
    "UPDATE category SET name = ? WHERE id = ?",
    [data.name, id],
    (err, res) => {
      if (err) return result(err, null);
      if (res.affectedRows === 0) return result({ kind: "not_found" }, null);
      result(null, { id, ...data });
    }
  );
};

Category.remove = (id, result) => {
  // Kiểm tra xem danh mục có đang được sử dụng bởi sách không
  sql.query("SELECT COUNT(*) as count FROM book WHERE category_id = ?", [id], (err, res) => {
    if (err) return result(err, null);
    if (res[0].count > 0) return result({ kind: "category_in_use" }, null);
    
    sql.query("DELETE FROM category WHERE id = ?", [id], (err, res) => {
      if (err) return result(err, null);
      if (res.affectedRows === 0) return result({ kind: "not_found" }, null);
      result(null, res);
    });
  });
};

module.exports = Category;