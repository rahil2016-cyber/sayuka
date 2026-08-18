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

// In-memory shop categories (for the "Shop by Category" section on Home page)
let shopCategories = [
  // Fashion Jewellery
  { id: 1, name: 'Necklaces', slug: 'necklaces', image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80' },
  { id: 2, name: 'Earrings', slug: 'earrings', image: 'https://images.unsplash.com/photo-1635767798638-3e25273a8236?w=600&q=80' },
  { id: 3, name: 'Pendant Sets', slug: 'pendant-sets', image: 'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=600&q=80' },
  { id: 4, name: 'Bangles & Bracelets', slug: 'bangles-bracelets', image: 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=600&q=80' },
  { id: 5, name: 'Rings', slug: 'rings', image: 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=600&q=80' },
  { id: 6, name: 'Maangtika', slug: 'maangtika', image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=600&q=80' },
  { id: 7, name: 'Matil', slug: 'matil', image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80' },
  { id: 8, name: 'Brooch', slug: 'brooch', image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80' },
  { id: 9, name: 'Hathpans', slug: 'hathpans', image: 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=600&q=80' },
  { id: 10, name: 'Bajubandh', slug: 'bajubandh', image: 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=600&q=80' },
  { id: 11, name: 'Belt', slug: 'belt', image: 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=600&q=80' },
  { id: 12, name: 'Nath', slug: 'nath', image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=600&q=80' },

  // Collections
  { id: 13, name: 'Antique', slug: 'antique', image: 'https://images.unsplash.com/photo-1610694955371-d4a3e0ce4b52?w=600&q=80' },
  { id: 14, name: 'CZ', slug: 'cz', image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=600&q=80' },
  { id: 15, name: 'Victorian', slug: 'victorian', image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80' },
  { id: 16, name: 'Jadau', slug: 'jadau', image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=600&q=80' },
  { id: 17, name: 'Pearls', slug: 'pearls', image: 'https://images.unsplash.com/photo-1635767798638-3e25273a8236?w=600&q=80' },
  { id: 18, name: 'Mangalsutra', slug: 'mangalsutra', image: 'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=600&q=80' },
  { id: 19, name: 'Mother of Pearl', slug: 'mother-of-pearl', image: 'https://images.unsplash.com/photo-1635767798638-3e25273a8236?w=600&q=80' },
  { id: 20, name: 'Anti-Tarnish', slug: 'anti-tarnish', image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80' },

  // Gold Plated 92.5 Silver Jewellery
  { id: 21, name: 'Gold-Plated Necklace', slug: 'gold-plated-necklace', image: 'https://images.unsplash.com/photo-1610694955371-d4a3e0ce4b52?w=600&q=80' },
  { id: 22, name: 'Gold-Plated Earrings', slug: 'gold-plated-earrings', image: 'https://images.unsplash.com/photo-1635767798638-3e25273a8236?w=600&q=80' },
  { id: 23, name: 'Gold-Plated Pendant Sets', slug: 'gold-plated-pendant-sets', image: 'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=600&q=80' },
  { id: 24, name: 'Gold-Plated Bracelets', slug: 'gold-plated-bracelets', image: 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=600&q=80' },
  { id: 25, name: 'Gold-Plated Accessories', slug: 'gold-plated-accessories', image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=600&q=80' },
  { id: 26, name: 'Gold-Plated Rings', slug: 'gold-plated-rings', image: 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=600&q=80' },
  { id: 27, name: 'Gold-Plated Chains', slug: 'gold-plated-chains', image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80' },

  // 92.5 Silver Jewellery
  { id: 28, name: 'Silver Earrings', slug: 'silver-earrings', image: 'https://images.unsplash.com/photo-1635767798638-3e25273a8236?w=600&q=80' },
  { id: 29, name: 'Silver Chains', slug: 'silver-chains', image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80' },
  { id: 30, name: 'Silver Pendant Sets', slug: 'silver-pendant-sets', image: 'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=600&q=80' },
  { id: 31, name: 'Silver Bracelets', slug: 'silver-bracelets', image: 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=600&q=80' },
  { id: 32, name: 'Silver Rings', slug: 'silver-rings', image: 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=600&q=80' },
  { id: 33, name: 'Silver Toe rings', slug: 'silver-toe-rings', image: 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=600&q=80' },
  { id: 34, name: 'Silver Accessories', slug: 'silver-accessories', image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=600&q=80' }
];

// ORDERS API
router.get('/orders', (req, res) => {
  res.json({ success: true, count: orders.length, data: orders });
});

router.post('/orders', (req, res) => {
  try {
    const { customer, address, items, totalAmount, paymentMethod } = req.body;
    const newOrder = {
      id: "#SAYUKA" + Math.floor(100000 + Math.random() * 900000),
      customer,
      address,
      items,
      totalAmount: parseFloat(totalAmount) || 0,
      paymentMethod: paymentMethod || "Online Payment",
      paymentStatus: "completed",
      orderStatus: "Pending",
      createdAt: new Date().toISOString()
    };
    orders.unshift(newOrder);
    res.status(201).json({ success: true, data: newOrder });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
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

// SHOP CATEGORIES API (for Home page "Shop by Category" section)
router.get('/categories', (req, res) => {
  res.json({ success: true, data: shopCategories });
});

router.post('/categories', (req, res) => {
  const { name, slug, image } = req.body;
  if (!name) return res.status(400).json({ success: false, message: 'Category name is required' });
  const newCat = {
    id: Date.now(),
    name: name.trim(),
    slug: slug || name.toLowerCase().trim().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, ''),
    image: image || 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80'
  };
  shopCategories.push(newCat);
  res.status(201).json({ success: true, data: newCat });
});

router.put('/categories/:id', (req, res) => {
  const catId = parseInt(req.params.id);
  const idx = shopCategories.findIndex(c => c.id === catId);
  if (idx === -1) return res.status(404).json({ success: false, message: 'Category not found' });
  shopCategories[idx] = { ...shopCategories[idx], ...req.body, id: catId };
  res.json({ success: true, data: shopCategories[idx] });
});

router.delete('/categories/:id', (req, res) => {
  const catId = parseInt(req.params.id);
  shopCategories = shopCategories.filter(c => c.id !== catId);
  res.json({ success: true, message: 'Category deleted' });
});

module.exports = router;
