// routes/loan.routes.js
/**
 * @swagger
 * components:
 *   schemas:
 *     Loan:
 *       type: object
 *       required:
 *         - user_id
 *         - loan_date
 *       properties:
 *         user_id:
 *           type: integer
 *         loan_date:
 *           type: string
 *           format: date
 *       example:
 *         user_id: 2
 *         loan_date: "2025-06-01"
 *     LoanDetail:
 *       type: object
 *       properties:
 *         loan_date:
 *           type: string
 *           format: date
 *         return_date:
 *           type: string
 *           format: date
 *           nullable: true
 *         title:
 *           type: string
 *       example:
 *         loan_date: "2025-06-01"
 *         return_date: "2025-06-10"
 *         title: "Clean Code"
 *
 * tags:
 *   name: Loans
 *   description: Quản lý phiếu mượn
 */

/**
 * @swagger
 * /api/loans/v1:
 *   post:
 *     summary: Tạo phiếu mượn
 *     tags: [Loans]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Loan'
 *     responses:
 *       201:
 *         description: Phiếu mượn đã được tạo
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Loan'
 *       400:
 *         description: Dữ liệu không hợp lệ hoặc người dùng không tồn tại
 *       500:
 *         description: Lỗi hệ thống
 *   get:
 *     summary: Lấy danh sách phiếu mượn của user
 *     tags: [Loans]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Danh sách phiếu mượn
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/LoanDetail'
 *       400:
 *         description: Người dùng không tồn tại
 *       401:
 *         description: Không tìm thấy thông tin người dùng
 *       500:
 *         description: Lỗi hệ thống
  * /api/loans/v1/full:
 *   post:
 *     summary: Tạo phiếu mượn kèm theo sách (Loan + LoanItem)
 *     tags: [Loans]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - user_id
 *               - loan_date
 *               - book_id
 *             properties:
 *               user_id:
 *                 type: integer
 *               loan_date:
 *                 type: string
 *                 format: date
 *               book_id:
 *                 type: integer
 *               return_date:
 *                 type: string
 *                 format: date
 *                 nullable: true
 *             example:
 *               user_id: 2
 *               loan_date: "2025-06-25"
 *               book_id: 3
 *               return_date: null
 *     responses:
 *       201:
 *         description: Tạo phiếu mượn và chi tiết thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 loan_id:
 *                   type: integer
 *                 loan_item:
 *                   $ref: '#/components/schemas/LoanItem'
 *       400:
 *         description: Dữ liệu không hợp lệ, người dùng không tồn tại, hoặc lỗi mượn sách
 *       500:
 *         description: Lỗi hệ thống
 * /api/loans/v1/{id}:
 *   get:
 *     summary: Lấy phiếu mượn theo ID
 *     tags: [Loans]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của phiếu mượn
 *     responses:
 *       200:
 *         description: Chi tiết phiếu mượn
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Loan'
 *       404:
 *         description: Không tìm thấy phiếu mượn
 *       500:
 *         description: Lỗi hệ thống
 *   put:
 *     summary: Cập nhật phiếu mượn
 *     tags: [Loans]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của phiếu mượn
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Loan'
 *     responses:
 *       200:
 *         description: Phiếu mượn đã được cập nhật
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Loan'
 *       400:
 *         description: Dữ liệu không hợp lệ hoặc người dùng không tồn tại
 *       404:
 *         description: Không tìm thấy phiếu mượn
 *       500:
 *         description: Lỗi hệ thống
 *   delete:
 *     summary: Xóa phiếu mượn
 *     tags: [Loans]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của phiếu mượn
 *     responses:
 *       200:
 *         description: Xóa phiếu mượn thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *       400:
 *         description: Phiếu mượn có sách chưa trả
 *       404:
 *         description: Không tìm thấy phiếu mượn
 *       500:
 *         description: Lỗi hệ thống
 *
 * /api/loans/v1/{id}/return:
 *   post:
 *     summary: Trả sách cho phiếu mượn
 *     tags: [Loans]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID của phiếu mượn
 *     responses:
 *       200:
 *         description: Trả sách thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 loan_id:
 *                   type: integer
 *                 return_date:
 *                   type: string
 *                   format: date
 *       400:
 *         description: Ngày trả không hợp lệ hoặc không có sách chưa trả
 *       404:
 *         description: Không tìm thấy phiếu mượn
 *       500:
 *         description: Lỗi hệ thống
 */

module.exports = app => {
  const ctrl = require("../controllers/loan.controller.js");
  const { verifyToken } = require("../middleware/auth.jwt.js");
  const role = require("../middleware/role.js");

  app.post("/api/loans/v1/:id/return", verifyToken, role.isUserOrLibrarian, ctrl.returnBooks);
  app.post("/api/loans/v1", verifyToken, role.isUserOrLibrarian, ctrl.create);
  app.post("/api/loans/v1/full", verifyToken, role.isUserOrLibrarian, ctrl.createLoanWithItem);
  app.get("/api/loans/v1", verifyToken, role.isUserOrLibrarian, ctrl.findAllByUser);
  app.get("/api/loans/v1/:id", verifyToken, role.isUserOrLibrarian, ctrl.findOne);
  app.put("/api/loans/v1/:id", verifyToken, role.isUserOrLibrarian, ctrl.update);
  app.delete("/api/loans/v1/:id", verifyToken, role.isUserOrLibrarian, ctrl.delete);
};