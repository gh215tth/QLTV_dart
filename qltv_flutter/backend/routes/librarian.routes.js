// routes/librarian.routes.js
/**
 * @swagger
 * components:
 *   schemas:
 *     Librarian:
 *       type: object
 *       properties:
 *         username:
 *           type: string
 *         email:
 *           type: string
 *         password:
 *           type: string
 *       example:
 *         username: emilie
 *         email: ile@example.com
 *         password: pass
 *   securitySchemes:
 *     bearerAuth:
 *       type: http
 *       scheme: bearer
 *       bearerFormat: JWT
 *
 * tags:
 *   name: Librarians
 *   description: Quản lý thủ thư
 */

/**
 * @swagger
 * /api/librarians:
 *   post:
 *     summary: Thêm thủ thư mới (chỉ librarian)
 *     tags: [Librarians]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Librarian'
 *     responses:
 *       201:
 *         description: Librarian created
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Librarian'
 *   get:
 *     summary: Lấy danh sách thủ thư
 *     tags: [Librarians]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Danh sách thủ thư
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Librarian'

 * /api/librarians/{id}:
 *   get:
 *     summary: Lấy thủ thư theo ID
 *     tags: [Librarians]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của thủ thư
 *     responses:
 *       200:
 *         description: Librarian detail
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Librarian'
 *   put:
 *     summary: Cập nhật thủ thư (chỉ librarian)
 *     tags: [Librarians]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của thủ thư
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Librarian'
 *     responses:
 *       200:
 *         description: Librarian updated
 *   delete:
 *     summary: Xóa thủ thư (chỉ librarian)
 *     tags: [Librarians]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của thủ thư
 *     responses:
 *       204:
 *         description: Librarian deleted

 * /api/librarians/login:
 *   post:
 *     summary: Đăng nhập thủ thư
 *     tags: [Librarians]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - username
 *               - password
 *             properties:
 *               username:
 *                 type: string
 *               password:
 *                 type: string
 *           example:
 *             username: admin
 *             password: admin123
 *     responses:
 *       200:
 *         description: Đăng nhập thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 librarian:
 *                   $ref: '#/components/schemas/Librarian'
 *                 accessToken:
 *                   type: string
 *       401:
 *         description: Sai thông tin đăng nhập
 */

module.exports = app => {
  const ctrl = require("../controllers/librarian.controller.js");
  const { verifyToken } = require("../middleware/auth.jwt.js");
  const role = require("../middleware/role.js");

  app.post("/api/librarians/login", ctrl.login);

  app.post("/api/librarians", verifyToken, role.isLibrarian, ctrl.create);
  app.get("/api/librarians", verifyToken, role.isLibrarian, ctrl.findAll);
  app.get("/api/librarians/:id", verifyToken, role.isLibrarian, ctrl.findOne);
  app.put("/api/librarians/:id", verifyToken, role.isLibrarian, ctrl.update);
  app.delete("/api/librarians/:id", verifyToken, role.isLibrarian, ctrl.delete);
};
