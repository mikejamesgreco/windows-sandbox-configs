const express = require('express');
const path = require('path');
const app = express();

const PORT = process.env.PORT || 8080;

// Serve static files from Angular's dist folder
// Updated path to include /browser
const distPath = path.join(__dirname, '../dist/my-app/browser');
app.use(express.static(distPath));

// Fallback to index.html for Angular routing
app.get('*', (req, res) => {
  res.sendFile(path.join(distPath, 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Angular app is running at http://localhost:${PORT}`);
});
