const express = require('express');
const fs = require('fs');

const app = express();
const port = 3000;

// Middleware to parse JSON bodies
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok' });
});

// Read items from JSON file
function getItems() {
    try {
        const data = fs.readFileSync('./data.json', 'utf8');
        return JSON.parse(data);
    } catch (err) {
        console.error('Error reading file:', err);
        return { items: [] };
    }
}

// GET endpoint to fetch all items
app.get('/items', (req, res) => {
    const data = getItems();
    res.json(data);
});

// POST endpoint to filter items
app.post('/items/filter', (req, res) => {
    const { category } = req.body;
    const data = getItems();
    
    if (!category) {
        return res.json(data);
    }

    const filteredItems = data.items.filter(item => item.category === category);
    res.json({ items: filteredItems });
});

app.listen(port, '0.0.0.0', () => {
    console.log(`Server running at http://0.0.0.0:${port}`);
});
