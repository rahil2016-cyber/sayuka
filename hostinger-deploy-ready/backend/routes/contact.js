const express = require('express');
const router = express.Router();

// Submit contact message
router.post('/', (req, res) => {
  try {
    const { name, email, phone, subject, message } = req.body;

    if (!name || !email || !message) {
      return res.status(400).json({
        success: false,
        message: 'Name, email and message are required',
      });
    }

    // In production, send email here
    console.log('New Contact Message:', { name, email, phone, subject, message });

    res.json({
      success: true,
      message: 'Your message has been received. We will get back to you shortly!',
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
