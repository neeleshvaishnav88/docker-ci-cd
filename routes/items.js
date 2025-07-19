const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();

// Define the Item schema
const itemSchema = new mongoose.Schema({
  title: { type: String, required: true },
  order: { type: Number, required: true },
  completed: { type: Boolean, default: false },
  createdOn: { type: Date, default: Date.now }
});

const Item = mongoose.model('Item', itemSchema);

// GET all items
router.get('/', async (req, res) => {
  try {
    const items = await Item.find().sort({ order: 1 });
    res.status(200).json(items);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET item by id
router.get('/:id', async (req, res) => {
  try {
    const item = await Item.findById(req.params.id);
    if (item) {
      res.status(200).json(item);
    } else {
      res.sendStatus(404);
    }
  } catch (err) {
    res.status(400).json({ error: 'Invalid ID' });
  }
});

// POST create new item
router.post('/', async (req, res) => {
  try {
    const lastItem = await Item.findOne().sort({ order: -1 });
    const newOrder = lastItem ? lastItem.order + 1 : 1;
    const newItem = new Item({
      title: req.body.title,
      order: newOrder,
      completed: false
    });
    await newItem.save();
    res.status(201).json(newItem);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// PUT update item
router.put('/:id', async (req, res) => {
  try {
    const updated = await Item.findByIdAndUpdate(
      req.params.id,
      {
        title: req.body.title,
        order: req.body.order,
        completed: req.body.completed,
        createdOn: req.body.createdOn
      },
      { new: true, runValidators: true }
    );
    if (updated) {
      res.sendStatus(204);
    } else {
      res.sendStatus(404);
    }
  } catch (err) {
    res.status(400).json({ error: 'Invalid ID or data' });
  }
});

// DELETE item
router.delete('/:id', async (req, res) => {
  try {
    const deleted = await Item.findByIdAndDelete(req.params.id);
    if (deleted) {
      res.sendStatus(204);
    } else {
      res.sendStatus(404);
    }
  } catch (err) {
    res.status(400).json({ error: 'Invalid ID' });
  }
});

module.exports = router;
