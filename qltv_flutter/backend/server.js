// server.js
const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const { swaggerUi, swaggerDocs } = require('./config/swagger');
const dotenv = require("dotenv");
dotenv.config();

const app = express();

// Enable CORS for all routes
app.use(cors());

// Parse requests of content-type: application/json
app.use(bodyParser.json());

// Parse requests of content-type: application/x-www-form-urlencoded
app.use(bodyParser.urlencoded({ extended: true }));

// Setup Swagger
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocs));

// Simple route
app.get("/", (req, res) => {
  res.json({ 
    message: "Welcome to the user API.",
    documentation: "Visit /api-docs for interactive API documentation"
  });
});

// Include routes
require('./routes/user.routes.js')(app);
require('./routes/book.routes.js')(app);
require('./routes/loan.routes.js')(app);
require('./routes/loanItem.routes.js')(app);
require('./routes/category.routes.js')(app);
require('./routes/auth.routes.js')(app);
require('./routes/librarian.routes.js')(app);

// Set port and start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on port ${PORT}.`);
  console.log(`Swagger documentation available at http://localhost:${PORT}/api-docs`);
});

const db = require('./config/db');

db.query("SELECT COUNT(*) as count FROM librarian", (err, result) => {
  if (err) throw err;
  if (result[0].count === 0) {
    const bcrypt = require('bcryptjs');
    const defaultLib = {
      username: "admin",
      email: "admin@example.com",
      password: bcrypt.hashSync("admin123", 10)
    };
    db.query("INSERT INTO librarian SET ?", defaultLib);
    console.log("⚠️ Created default librarian account: admin/admin123");
  }
});
