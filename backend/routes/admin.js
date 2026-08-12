const express = require('express');
const router = express.Router();
const products = require('../data/products');

// In-memory orders state
let orders = [
  {
    id: "#POPMRSEDLIQE18302",
    customer: { name: "MOHAMMED RAHIL", email: "rahil2016ok@gmail.com", phone: "08431463400" },
    address: "2633/1, MCC B Block, Davanagere, Karnataka - 577004",
    items: [{ name: "Royal Bloom Pendant", price: 2620.00, qty: 1 }],
    totalAmount: 2620.00,
    paymentMethod: "Cashfree",
    paymentStatus: "completed",
    orderStatus: "Pending",
    createdAt: new Date().toISOString()
  },
  {
    id: "#POPMRRJB4RLTOEGW",
    customer: { name: "MOHAMMED RAHIL", email: "rahil2016ok@gmail.com", phone: "08431463400" },
    address: "2633/1, MCC B Block, Davanagere, Karnataka - 577004",
    items: [{ name: "Silver CZ Sparkle Bracelet", price: 1.00, qty: 1 }],
    totalAmount: 1.00,
    paymentMethod: "Cashfree",
    paymentStatus: "completed",
    orderStatus: "Processing",
    createdAt: new Date().toISOString()
  },
  {
    id: "#POPMRRJA9QRMVS8S",
    customer: { name: "MOHAMMED RAHIL", email: "rahil2016ok@gmail.com", phone: "08431463400" },
    address: "2633/1, MCC B Block, Davanagere, Karnataka - 577004",
    items: [{ name: "Kundan Hair Maangtika", price: 1.00, qty: 1 }],
    totalAmount: 1.00,
    paymentMethod: "Cashfree",
    paymentStatus: "pending",
    orderStatus: "Pending",
    createdAt: new Date().toISOString()
  }
];

// In-memory banners state
let banners = [
  {
    id: 1,
    title: "Timeless Heritage Collection",
    subtitle: "Handcrafted gold plated 92.5 silver & Jadau sets",
    image: "https://images.unsplash.com/photo-1610694955371-d4a3e0ce4b52?w=1600&q=95",
    link: "/collections?category=gold-plated-necklace"
  },
  {
    id: 2,
    title: "Modern CZ & Diamond Sparkle",
    subtitle: "Brilliant craftsmanship designed to shine for every occasion",
    image: "https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=1600&q=95",
    link: "/collections?category=cz"
  }
];

// ORDERS API
router.get('/orders', (req, res) => {
  res.json({ success: true, count: orders.length, data: orders });
});

router.put('/orders/:id/status', (req, res) => {
  const { status } = req.body;
  const order = orders.find(o => o.id === req.params.id);
  if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
  order.orderStatus = status;
  res.json({ success: true, data: order });
});

// BANNERS API
router.get('/banners', (req, res) => {
  res.json({ success: true, data: banners });
});

router.post('/banners', (req, res) => {
  const { title, subtitle, image, link } = req.body;
  const newBanner = {
    id: Date.now(),
    title: title || 'New Collection',
    subtitle: subtitle || '',
    image: image || 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=1600&q=95',
    link: link || '/collections'
  };
  banners.unshift(newBanner);
  res.status(201).json({ success: true, data: newBanner });
});

router.delete('/banners/:id', (req, res) => {
  const bannerId = parseInt(req.params.id);
  banners = banners.filter(b => b.id !== bannerId);
  res.json({ success: true, message: 'Banner deleted' });
});

module.exports = router;
