// routes/category.routes.js
/**
 * @swagger
 * components:
 *   schemas:
 *     Category:
 *       type: object
 *       required:
 *         - name
 *       properties:
 *         name:
 *           type: string
 *       example:
 *         name: "Programming"
 *     BookInCategory:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *           description: ID của sách
 *         title:
 *           type: string
 *           description: Tên sách
 *         author:
 *           type: string
 *           description: Tên tác giả
 *         category_id:
 *           type: integer
 *           description: ID danh mục chứa sách
 *         quantity:
 *           type: integer
 *           description: Số lượng còn lại
 *         available:
 *           type: boolean
 *           description: Trạng thái còn sách để mượn
 *       example:
 *         id: 12
 *         title: "Flutter cơ bản"
 *         author: "Nguyễn Văn A"
 *         category_id: 2
 *         quantity: 3
 *         available: true
 *
 * tags:
 *   name: Categories
 *   description: Quản lý danh mục sách
 */

/**
 * @swagger
 * /api/categories/v1:
 *   post:
 *     summary: Thêm danh mục sách (chỉ librarian)
 *     tags: [Categories]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Category'
 *     responses:
 *       201:
 *         description: Danh mục đã được tạo
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Category'
 *       500:
 *         description: Lỗi hệ thống
 *   get:
 *     summary: Lấy danh sách danh mục sách
 *     tags: [Categories]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Danh sách danh mục sách
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Category'
 *       500:
 *         description: Lỗi hệ thống
 *
 * /api/categories/v1/{id}:
 *   get:
 *     summary: Lấy danh mục theo ID
 *     tags: [Categories]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của danh mục
 *     responses:
 *       200:
 *         description: Chi tiết danh mục
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Category'
 *       404:
 *         description: Không tìm thấy danh mục
 *       500:
 *         description: Lỗi hệ thống
 *   put:
 *     summary: Cập nhật danh mục (chỉ librarian)
 *     tags: [Categories]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của danh mục
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Category'
 *     responses:
 *       200:
 *         description: Danh mục đã được cập nhật
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Category'
 *       400:
 *         description: Dữ liệu không hợp lệ
 *       404:
 *         description: Không tìm thấy danh mục
 *       500:
 *         description: Lỗi hệ thống
 *   delete:
 *     summary: Xóa danh mục (chỉ librarian)
 *     tags: [Categories]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của danh mục
 *     responses:
 *       200:
 *         description: Xóa danh mục thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *       400:
 *         description: Danh mục đang được sử dụng
 *       404:
 *         description: Không tìm thấy danh mục
 *       500:
 *         description: Lỗi hệ thống
 *
 * /api/categories/v1/{id}/books:
 *   get:
 *     summary: Lấy danh sách sách theo danh mục
 *     tags: [Categories]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID của danh mục
 *     responses:
 *       200:
 *         description: Danh sách sách thuộc danh mục
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/BookInCategory'
 *       400:
 *         description: ID danh mục không hợp lệ
 *       404:
 *         description: Không tìm thấy danh mục
 *       500:
 *         description: Lỗi hệ thống
 */

module.exports = app => {
  const ctrl = require("../controllers/category.controller.js");
  const { verifyToken } = require("../middleware/auth.jwt.js");
  const role = require("../middleware/role.js");

  app.post("/api/categories/v1", verifyToken, role.isLibrarian, ctrl.create);
  app.get("/api/categories/v1", verifyToken, role.isUserOrLibrarian, ctrl.findAll);
  app.get("/api/categories/v1/:id", verifyToken, role.isUserOrLibrarian, ctrl.findOne);
  app.put("/api/categories/v1/:id", verifyToken, role.isLibrarian, ctrl.update);
  app.delete("/api/categories/v1/:id", verifyToken, role.isLibrarian, ctrl.delete);
  app.get("/api/categories/v1/:id/books", verifyToken, role.isUserOrLibrarian, ctrl.getBooksByCategory);
};