const http = require('http');
const express = require('express');
const mongoose = require('mongoose');

const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./swagger.json');

const cors = require('cors');
const csrf = require('csurf');
const cookieParser = require('cookie-parser');

const itemsRouter = require('./routes/items');

const app = express();

app.use(cors());

app.use(express.json());
app.use(cookieParser());
app.use(csrf({ cookie: true }));

// Add a test route for CSRF token
app.get('/form', (req, res) => {
    res.send(`CSRF token: ${req.csrfToken()}`);
});

app.use('/items', itemsRouter);

app.use('/', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

const port = process.env.PORT || 5000;
const mongoUrl = process.env.MONGO_URL || 'mongodb://localhost:27017/tododb';

mongoose.connect(mongoUrl)
    .then(() => {
        console.log('Connected to MongoDB');
        app.listen(port, () => {
            console.log('Server listening on port ' + port);
        });
    })
    .catch((err) => {
        console.error('Failed to connect to MongoDB:', err);
        process.exit(1);
    });


module.exports = app;
