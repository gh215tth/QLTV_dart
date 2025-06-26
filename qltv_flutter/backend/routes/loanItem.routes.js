// routes/loanItem.routes.js
/**
 * @swagger
 * components:
 *   schemas:
 *     LoanItem:
 *       type: object
 *       required:
 *         - loan_id
 *         - book_id
 *       properties:
 *         loan_id:
 *           type: integer
 *         book_id:
 *           type: integer
 *         return_date:
 *           type: string
 *           format: date
 *           nullable: true
 *       example:
 *         loan_id: 1
 *         book_id: 2
 *         return_date: "2025-06-30"
 *
 * tags:
 *   name: LoanItems
 *   description: Quản lý chi tiết phiếu mượn
 */

/**
 * @swagger
 * /api/loan-items/v1:
 *   post:
 *     summary: Thêm chi tiết phiếu mượn
 *     tags: [LoanItems]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/LoanItem'
 *     responses:
 *       201:
 *         description: Chi tiết phiếu mượn đã được tạo
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/LoanItem'
 *       400:
 *         description: Dữ liệu không hợp lệ, phiếu mượn/sách không tồn tại, hoặc sách đã hết
 *       500:
 *         description: Lỗi hệ thống
 *   get:
 *     summary: Lấy danh sách chi tiết phiếu mượn
 *     tags: [LoanItems]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Danh sách chi tiết phiếu mượn
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/LoanItem'
 *       500:
 *         description: Lỗi hệ thống
 *
 * /api/loan-items/v1/{id}:
 *   get:
 *     summary: Lấy chi tiết phiếu mượn theo ID
 *     tags: [LoanItems]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của chi tiết phiếu mượn
 *     responses:
 *       200:
 *         description: Chi tiết phiếu mượn
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/LoanItem'
 *       404:
 *         description: Không tìm thấy chi tiết phiếu mượn
 *       500:
 *         description: Lỗi hệ thống
 *   put:
 *     summary: Cập nhật chi tiết phiếu mượn
 *     tags: [LoanItems]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của chi tiết phiếu mượn
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/LoanItem'
 *     responses:
 *       200:
 *         description: Chi tiết phiếu mượn đã được cập nhật
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/LoanItem'
 *       400:
 *         description: Dữ liệu không hợp lệ, phiếu mượn/sách không tồn tại
 *       404:
 *         description: Không tìm thấy chi tiết phiếu mượn
 *       500:
 *         description: Lỗi hệ thống
 *   delete:
 *     summary: Xóa chi tiết phiếu mượn
 *     tags: [LoanItems]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của chi tiết phiếu mượn
 *     responses:
 *       200:
 *         description: Xóa chi tiết phiếu mượn thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *       404:
 *         description: Không tìm thấy chi tiết phiếu mượn
 *       500:
 *         description: Lỗi hệ thống
 */

/**
 * @swagger
 * /api/loan-items/v1/loan/{loan_id}:
 *   get:
 *     summary: Lấy danh sách chi tiết phiếu mượn theo loan_id
 *     tags: [LoanItems]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: loan_id
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của phiếu mượn
 *     responses:
 *       200:
 *         description: Danh sách chi tiết phiếu mượn theo loan_id
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/LoanItem'
 *       404:
 *         description: Không tìm thấy chi tiết phiếu mượn với loan_id tương ứng
 *       500:
 *         description: Lỗi hệ thống
 */


module.exports = app => {
  const ctrl = require("../controllers/loanItem.controller.js");
  const { verifyToken } = require("../middleware/auth.jwt.js");
  const role = require("../middleware/role.js");

  app.post("/api/loan-items/v1", verifyToken, role.isUserOrLibrarian, ctrl.create);
  app.get("/api/loan-items/v1", verifyToken, role.isUserOrLibrarian, ctrl.findAll);
  app.get("/api/loan-items/v1/:id", verifyToken, role.isUserOrLibrarian, ctrl.findOne);
  app.put("/api/loan-items/v1/:id", verifyToken, role.isUserOrLibrarian, ctrl.update);
  app.delete("/api/loan-items/v1/:id", verifyToken, role.isUserOrLibrarian, ctrl.delete);
  app.get("/api/loan-items/v1/loan/:loan_id", verifyToken, role.isUserOrLibrarian, ctrl.findByLoanId);
};