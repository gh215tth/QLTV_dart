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

module.exports = {
  isLibrarian,
  isUser,
  isUserOrLibrarian
};
