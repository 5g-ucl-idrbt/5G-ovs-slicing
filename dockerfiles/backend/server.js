// server.js
const express = require('express');
const path = require('path'); // Add this line
const Datastore = require('nedb');

const app = express();
const PORT = 3000;

const db = new Datastore({ filename: 'data.db', autoload: true });


// Insert valid account data into the database
db.insert(
  [
    { accountNumber: '123456', password: 'password123', balance: 1000 },
    { accountNumber: '987654', password: 'letmein', balance: 500 }
  ],
  (err) => {
    if (err) {
      console.error('Error inserting data into database:', err);
    } else {
      console.log('Initial data inserted into the database.');
    }
  }
);




// Serve the frontend static files
app.use(express.static(path.join(__dirname, '../frontend')));

//app.use(express.static('frontend'));

app.post('/login', express.json(), (req, res) => {
    const { accountNumber, password } = req.body;

    db.findOne({ accountNumber, password }, (err, account) => {
        if (err || !account) {
            res.status(401).send('Invalid credentials');
        } else {
            res.status(200).json(account);
        }
    });
});

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
