// middleware/role.js
const isLibrarian = (req, res, next) => {
  console.log(">> Role check: ", req.user);
  if (req.user && req.user.role === "librarian") {
    return next();
  }
  return res.status(403).json({ message: "Require librarian role!" });
};

const isUser = (req, res, next) => {
  if (req.user && req.user.role === "user") {
    return next();
  }
  return res.status(403).json({ message: "Require user role!" });
};

const isUserOrLibrarian = (req, res, next) => {
  if (req.user && (req.user.role === "user" || req.user.role === "librarian")) {
    return next();
  }
  return res.status(403).json({ message: "Require user or librarian role!" });
};

const canAccessUserOrSelf = (req, res, next) => {
  const targetId = parseInt(req.params.userId);
  const requesterId = parseInt(req.user.id);
  const isLibrarian = req.user.role === 'librarian';

  if (isLibrarian || targetId === requesterId) {
    return next();
  }

  return res.status(403).json({ message: "Bạn không có quyền truy cập thông tin này." });
};

module.exports = {
  isLibrarian,
  isUser,
  isUserOrLibrarian,
  canAccessUserOrSelf
};
  