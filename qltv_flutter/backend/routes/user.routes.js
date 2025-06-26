/**
 * @swagger
 * components:
 *   schemas:
 *     User:
 *       type: object
 *       properties:
 *         username: { type: string }
 *         email:    { type: string }
 *         password: { type: string }
 *         role:     { type: string, enum: [user, librarian] }
 *       example:
 *         username: gh
 *         email: gh@example.com
 *         password: pass
 *         role: user
 *   securitySchemes:
 *     bearerAuth:
 *       type: http
 *       scheme: bearer
 *       bearerFormat: JWT
 *
 * tags:
 *   name: Users
 *   description: Quản lý người dùng (chỉ librarian)
 */

/**
 * @swagger
 * /api/users:
 *   post:
 *     summary: Tạo user mới (chỉ librarian)
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/User'
 *     responses:
 *       201:
 *         description: User created
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/User'
 *   get:
 *     summary: Lấy danh sách user (chỉ librarian)
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Danh sách user
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/User'
 *
 * /api/users/{userId}:
 *   get:
 *     summary: Lấy user theo ID (chỉ librarian)
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của user
 *     responses:
 *       200:
 *         description: User detail
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/User'
 *   put:
 *     summary: Cập nhật user (chỉ librarian)
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của user
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/User'
 *     responses:
 *       200:
 *         description: User updated
 *   delete:
 *     summary: Xóa user (chỉ librarian)
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của user
 *     responses:
 *       204:
 *         description: User deleted
 *
 * /api/users/login:
 *   post:
 *     summary: Đăng nhập user
 *     tags: [Users]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               username: { type: string }
 *               password: { type: string }
 *             required: [username, password]
 *     responses:
 *       200:
 *         description: Đăng nhập thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message: { type: string }
 *                 user:    { $ref: '#/components/schemas/User' }
 *                 accessToken: { type: string }
 *       401:
 *         description: Sai thông tin đăng nhập
 *
 * /api/users/{userId}/borrowed-books:
 *   get:
 *     summary: Lấy danh sách book_id mà user đang mượn (chưa trả)
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID của user
 *     responses:
 *       200:
 *         description: Danh sách book_id
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: integer
 */

module.exports = app => {
  const ctrl = require("../controllers/user.controller.js");
  const { verifyToken } = require("../middleware/auth.jwt.js");
  const role = require("../middleware/role.js");

  // Auth
  app.post("/api/users/login", ctrl.login);

  // User CRUD (chỉ librarian)
  app.post("/api/users", verifyToken, role.isLibrarian, ctrl.create);
  app.get("/api/users", verifyToken, role.isLibrarian, ctrl.findAll);
  app.get("/api/users/:userId", verifyToken, role.isLibrarian, ctrl.findOne);
  app.put("/api/users/:userId", verifyToken, role.isLibrarian, ctrl.update);
  app.delete("/api/users/:userId", verifyToken, role.isLibrarian, ctrl.delete);

  // Get borrowed book ids (cho user hiện tại hoặc librarian)
  app.get("/api/users/:userId/borrowed-books", verifyToken, ctrl.getBorrowedBookIds);
};
