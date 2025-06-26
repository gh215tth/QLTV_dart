// routes/book.routes.js
/**
 * @swagger
 * components:
 *   schemas:
 *     Book:
 *       type: object
 *       required:
 *         - title
 *         - category_id
 *       properties:
 *         title:
 *           type: string
 *         author:
 *           type: string
 *         category_id:
 *           type: integer
 *         quantity:
 *           type: integer
 *           description: "Số lượng còn lại của sách"
 *       example:
 *         title: "Clean Code"
 *         author: "Robert C. Martin"
 *         category_id: 1
 *         quantity: 5
 *   securitySchemes:
 *     bearerAuth:
 *       type: http
 *       scheme: bearer
 *       bearerFormat: JWT
 *
 * tags:
 *   name: Books
 *   description: CRUD sách và tìm kiếm
 */

/**
 * @swagger
 * /api/books/v1:
 *   post:
 *     summary: Thêm sách mới (chỉ librarian)
 *     tags: [Books]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Book'
 *     responses:
 *       201:
 *         description: Sách đã được tạo thành công
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Book'
 *       400:
 *         description: Dữ liệu không hợp lệ hoặc danh mục không tồn tại
 *       500:
 *         description: Lỗi hệ thống
 *   get:
 *     summary: Lấy danh sách sách (có hỗ trợ tìm kiếm ?q=)
 *     tags: [Books]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: q
 *         schema:
 *           type: string
 *         required: false
 *         description: Từ khóa tìm kiếm theo tên sách hoặc tác giả
 *     responses:
 *       200:
 *         description: Danh sách sách
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Book'
 *       500:
 *         description: Lỗi hệ thống
 *
 * /api/books/category/v1/{categoryId}:
 *   get:
 *     summary: Lấy danh sách sách theo danh mục
 *     tags: [Books]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: categoryId
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của danh mục
 *     responses:
 *       200:
 *         description: Danh sách sách thuộc danh mục
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Book'
 *       400:
 *         description: Danh mục không tồn tại
 *       500:
 *         description: Lỗi hệ thống
 *
 * /api/books/v1/{id}:
 *   get:
 *     summary: Lấy thông tin sách theo ID
 *     tags: [Books]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của sách
 *     responses:
 *       200:
 *         description: Chi tiết sách
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Book'
 *       404:
 *         description: Không tìm thấy sách
 *       500:
 *         description: Lỗi hệ thống
 *   put:
 *     summary: Cập nhật thông tin sách (chỉ librarian)
 *     tags: [Books]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của sách
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Book'
 *     responses:
 *       200:
 *         description: Sách đã được cập nhật
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Book'
 *       400:
 *         description: Dữ liệu không hợp lệ hoặc danh mục không tồn tại
 *       404:
 *         description: Không tìm thấy sách
 *       500:
 *         description: Lỗi hệ thống
 *   delete:
 *     summary: Xóa sách (chỉ librarian)
 *     tags: [Books]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của sách
 *     responses:
 *       200:
 *         description: Xóa thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *       400:
 *         description: Sách đang được mượn
 *       404:
 *         description: Không tìm thấy sách
 *       500:
 *         description: Lỗi hệ thống
 */

module.exports = app => {
  const ctrl = require("../controllers/book.controller.js");
  const { verifyToken } = require("../middleware/auth.jwt.js");
  const role = require("../middleware/role.js");

  app.post("/api/books/v1", verifyToken, role.isLibrarian, ctrl.create);
  app.get("/api/books/v1", verifyToken, role.isUserOrLibrarian, ctrl.findAll);
  app.get("/api/books/v1/:id", verifyToken, role.isUserOrLibrarian, ctrl.findOne);
  app.put("/api/books/v1/:id", verifyToken, role.isLibrarian, ctrl.update);
  app.delete("/api/books/v1/:id", verifyToken, role.isLibrarian, ctrl.delete);
  app.get("/api/books/category/v1/:categoryId", verifyToken, role.isUserOrLibrarian, ctrl.findByCategory);
};