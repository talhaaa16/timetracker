const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();
app.use(cors());
app.use(express.json());

mongoose.connect(process.env.MONGODB_CLUSTER_URL)
    .then(() => console.log('✔ Connected to MongoDB'))
    .catch(err => console.error('❌ MongoDB connection error:', err));

const userSchema = new mongoose.Schema({
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    firstName: String,
    lastName: String,
}, { strict: false });
const User = mongoose.model('User', userSchema);

const logSchema = new mongoose.Schema({
    uid: { type: String, required: true },
    event_name: { type: String, required: true },
    details: { type: String, default: "" },
    timestamp: { type: Date, default: Date.now },
}, { strict: false });
const Log = mongoose.model('Log', logSchema);

app.post('/auth/signup', async (req, res) => {
    try {
        const { email, password, firstName, lastName } = req.body;
        const existing = await User.findOne({ email });
        if (existing) return res.status(400).json({ error: 'Email already exists' });

        const hashedPassword = await bcrypt.hash(password, 10);
        const user = new User({ email, password: hashedPassword, firstName, lastName });
        await user.save();

        const token = jwt.sign({ uid: user._id }, 'secret_key');
        res.json({ token, uid: user._id, email, firstName, lastName });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

app.post('/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        const user = await User.findOne({ email });
        if (!user) return res.status(400).json({ error: 'User not found' });

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) return res.status(400).json({ error: 'Invalid password' });

        const token = jwt.sign({ uid: user._id }, 'secret_key');
        res.json({ token, uid: user._id, email, firstName: user.firstName, lastName: user.lastName });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

app.get('/logs/:uid', async (req, res) => {
    try {
        const logs = await Log.find({ uid: req.params.uid }).sort({ timestamp: -1 });
        res.json(logs);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

app.post('/logs', async (req, res) => {
    try {
        const { uid, event_name, details } = req.body;
        const log = new Log({ uid, event_name, details, timestamp: new Date() });
        await log.save();
        res.json(log);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

app.listen(3000, () => console.log('Backend API running on http://localhost:3000'));
