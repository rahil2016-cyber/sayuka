const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const verifyAdmin = require('../middleware/auth');
const loginLimiter = require('../middleware/limiter');
const products = require('../data/products');
const db = require('../config/db');
const whatsappService = require('../services/whatsappService');

// In-memory orders state (fallback)
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

// In-memory banners state — starts empty, managed via Admin panel only
let banners = [];


// In-memory shop categories (fallback)
let shopCategories = [
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
  { id: 12, name: 'Nath', slug: 'nath', image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=600&q=80' }
];

// AUTHENTICATION API
router.post('/login', loginLimiter, async (req, res) => {
  try {
    const { username, password } = req.body;

    const envUsername = process.env.ADMIN_USERNAME;
    const envPasswordHash = process.env.ADMIN_PASSWORD_HASH;
    const jwtSecret = process.env.JWT_SECRET;

    if (!envUsername || !envPasswordHash || !jwtSecret) {
      return res.status(500).json({ success: false, message: 'Server authentication configuration is missing.' });
    }

    if (username !== envUsername) {
      return res.status(401).json({ success: false, message: 'Invalid username or password.' });
    }

    const isMatch = await bcrypt.compare(password, envPasswordHash);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid username or password.' });
    }

    const token = jwt.sign(
      { username: envUsername, role: 'admin' },
      jwtSecret,
      { expiresIn: '12h' }
    );

    res.cookie('admin_token', token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: process.env.NODE_ENV === 'production' ? 'strict' : 'lax',
      maxAge: 12 * 60 * 60 * 1000 // 12 hours
    });

    res.json({ success: true, message: 'Login successful' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/logout', (req, res) => {
  res.clearCookie('admin_token', {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: process.env.NODE_ENV === 'production' ? 'strict' : 'lax'
  });
  res.json({ success: true, message: 'Logged out successfully' });
});

router.get('/verify', verifyAdmin, (req, res) => {
  res.json({ success: true, admin: { username: req.admin.username } });
});

// ORDERS API
router.get('/orders', verifyAdmin, async (req, res) => {
  try {
    if (db.useDb()) {
      const [rows] = await db.pool().query('SELECT * FROM orders ORDER BY created_at DESC');
      
      const ordersWithItems = [];
      for (const order of rows) {
        const [items] = await db.pool().query(`
          SELECT oi.*, p.images 
          FROM order_items oi 
          LEFT JOIN products p ON oi.product_id = p.id 
          WHERE oi.order_id = ?
        `, [order.id]);
        ordersWithItems.push({
          id: order.id,
          orderStatus: order.order_status || 'Pending',
          paymentStatus: order.payment_status || 'Pending',
          paymentMethod: order.payment_method || 'Online',
          createdAt: order.created_at,
          customer: {
            name: order.customer_name,
            email: order.customer_email,
            phone: order.customer_phone
          },
          address: order.shipping_address,
          totalAmount: parseFloat(order.total_amount),
          whatsappConsent: !!order.whatsapp_consent,
          items: items.map(i => {
            let img = '';
            if (i.images) {
              try { 
                const parsed = JSON.parse(i.images);
                img = Array.isArray(parsed) ? parsed[0] : parsed;
              } catch(e) { 
                img = i.images; 
              }
            }
            return {
              ...i,
              name: i.product_name,
              price: parseFloat(i.price),
              image: img
            };
          })
        });
      }
      return res.json({ success: true, count: ordersWithItems.length, data: ordersWithItems });
    }

    res.json({ success: true, count: orders.length, data: orders });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/orders', async (req, res) => {
  try {
    const { customer, address, items, totalAmount, paymentMethod, whatsappConsent } = req.body;

    if (db.useDb()) {
      const conn = await db.pool().getConnection();
      await conn.beginTransaction();

      try {
        const orderId = "#SAYUKA" + Math.floor(100000 + Math.random() * 900000);

        // 1. Insert order
        await conn.query(`
          INSERT INTO orders (id, customer_name, customer_email, customer_phone, whatsapp_consent, shipping_address, total_amount, payment_method, payment_status, order_status)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Pending', 'Pending')
        `, [
          orderId,
          customer.name,
          customer.email,
          customer.phone,
          whatsappConsent ? 1 : 0,
          address,
          parseFloat(totalAmount) || 0,
          paymentMethod || "Online Payment"
        ]);

        // 2. Update stock & Insert line items
        for (const item of items) {
          const [prodRows] = await conn.query('SELECT id, stock FROM products WHERE name = ? FOR UPDATE', [item.name]);
          
          if (prodRows.length > 0) {
            const prodId = prodRows[0].id;
            const currentStock = prodRows[0].stock;

            if (currentStock < item.qty) {
              throw new Error(`Insufficient stock for product "${item.name}". Only ${currentStock} units left.`);
            }

            await conn.query(`
              UPDATE products 
              SET stock = stock - ?, in_stock = CASE WHEN stock <= 0 THEN 0 ELSE 1 END 
              WHERE id = ?
            `, [item.qty, prodId]);

            await conn.query(`
              INSERT INTO order_items (order_id, product_id, product_name, price, qty)
              VALUES (?, ?, ?, ?, ?)
            `, [
              orderId,
              prodId,
              item.name,
              parseFloat(item.price) || 0,
              parseInt(item.qty) || 1
            ]);
          } else {
            await conn.query(`
              INSERT INTO order_items (order_id, product_id, product_name, price, qty)
              VALUES (?, NULL, ?, ?, ?)
            `, [
              orderId,
              item.name,
              parseFloat(item.price) || 0,
              parseInt(item.qty) || 1
            ]);
          }
        }

        await conn.commit();
        
        const createdOrder = {
          id: orderId,
          customer,
          address,
          items,
          totalAmount: parseFloat(totalAmount),
          paymentMethod: paymentMethod || "Online Payment",
          orderStatus: 'Pending',
          paymentStatus: 'Pending'
        };
        
        // Send WhatsApp confirmation if consented
        if (whatsappConsent && customer.phone) {
          whatsappService.sendOrderConfirmation(customer.phone, orderId, customer.name);
        }

        return res.status(201).json({ success: true, data: createdOrder });
      } catch (transactionErr) {
        await conn.rollback();
        return res.status(400).json({ success: false, message: transactionErr.message });
      } finally {
        conn.release();
      }
    }

    // In-memory fallback
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

    // Send WhatsApp confirmation if consented
    if (whatsappConsent && customer.phone) {
      whatsappService.sendOrderConfirmation(customer.phone, newOrder.id, customer.name);
    }

    res.status(201).json({ success: true, data: newOrder });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

const cashfreeService = require('../services/cashfreeService');

// Create Cashfree Payment Session
router.post('/orders/create-payment-session', async (req, res) => {
  try {
    const { totalAmount, customer } = req.body;
    const orderId = "PAY_" + Math.floor(100000 + Math.random() * 900000);
    
    const sessionData = await cashfreeService.createPaymentSession(orderId, totalAmount, customer);
    
    res.json({ success: true, payment_session_id: sessionData.payment_session_id, order_id: orderId });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUBLIC ORDER TRACKING - no auth required
router.get('/track/:orderId', async (req, res) => {
  try {
    const orderId = req.params.orderId;

    if (db.useDb()) {
      const [rows] = await db.pool().query(
        'SELECT id, customer_name, total_amount, payment_status, order_status, created_at FROM orders WHERE id = ?',
        [orderId]
      );
      if (rows.length === 0) {
        return res.status(404).json({ success: false, message: 'Order not found. Please check the tracking code.' });
      }
      const order = rows[0];
      const [items] = await db.pool().query(`
        SELECT oi.product_name, oi.qty, p.images 
        FROM order_items oi
        LEFT JOIN products p ON oi.product_id = p.id 
        WHERE oi.order_id = ?
      `, [orderId]);
      // Mask customer name for privacy (show first name only)
      const nameParts = (order.customer_name || '').split(' ');
      const maskedName = nameParts[0] + (nameParts.length > 1 ? ' ' + nameParts[nameParts.length - 1][0] + '.' : '');
      return res.json({
        success: true,
        data: {
          id: order.id,
          customerName: maskedName,
          totalAmount: parseFloat(order.total_amount),
          paymentStatus: order.payment_status,
          orderStatus: order.order_status,
          createdAt: order.created_at,
          itemCount: items.length,
          items: items.map(i => {
            let img = '';
            if (i.images) {
              try { 
                const parsed = JSON.parse(i.images);
                img = Array.isArray(parsed) ? parsed[0] : parsed;
              } catch(e) { img = i.images; }
            }
            return { name: i.product_name, qty: i.qty, image: img };
          })
        }
      });
    }

    // In-memory fallback
    const order = orders.find(o => o.id === orderId);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found. Please check the tracking code.' });
    }
    const nameParts = (order.customer?.name || '').split(' ');
    const maskedName = nameParts[0] + (nameParts.length > 1 ? ' ' + nameParts[nameParts.length - 1][0] + '.' : '');
    return res.json({
      success: true,
      data: {
        id: order.id,
        customerName: maskedName,
        totalAmount: order.totalAmount,
        paymentStatus: order.paymentStatus,
        orderStatus: order.orderStatus,
        createdAt: order.createdAt,
        itemCount: order.items?.length || 0,
        items: (order.items || []).map(i => ({ name: i.name, qty: i.qty }))
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.put('/orders/:id/status', verifyAdmin, async (req, res) => {
  try {
    const { status } = req.body;

    if (db.useDb()) {
      const [result] = await db.pool().query('UPDATE orders SET order_status = ? WHERE id = ?', [status, req.params.id]);
      if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Order not found' });
      
      const [rows] = await db.pool().query('SELECT * FROM orders WHERE id = ?', [req.params.id]);
      const order = rows[0];

      // Send WhatsApp update if consented
      if (order.whatsapp_consent && order.customer_phone) {
        if (status === 'Shipped') {
          whatsappService.sendOrderShipped(order.customer_phone, order.id, 'N/A');
        } else if (status === 'Delivered') {
          whatsappService.sendOrderDelivered(order.customer_phone, order.id);
        }
      }

      return res.json({ success: true, data: order });
    }

    const order = orders.find(o => o.id === req.params.id);
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    order.orderStatus = status;

    // Send WhatsApp update if consented
    if (order.customer?.phone) {
      if (status === 'Shipped') {
        whatsappService.sendOrderShipped(order.customer.phone, order.id, 'N/A');
      } else if (status === 'Delivered') {
        whatsappService.sendOrderDelivered(order.customer.phone, order.id);
      }
    }

    res.json({ success: true, data: order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// BANNERS API
router.get('/banners', async (req, res) => {
  try {
    if (db.useDb()) {
      const [rows] = await db.pool().query('SELECT * FROM banners ORDER BY id DESC');
      return res.json({ success: true, data: rows });
    }
    res.json({ success: true, data: banners });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/banners', verifyAdmin, async (req, res) => {
  try {
    const { title, subtitle, image, link } = req.body;

    if (db.useDb()) {
      const [result] = await db.pool().query(`
        INSERT INTO banners (title, subtitle, image, link)
        VALUES (?, ?, ?, ?)
      `, [
        title || 'New Collection',
        subtitle || '',
        image || 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=1600&q=95',
        link || '/collections'
      ]);

      const newBanner = {
        id: result.insertId,
        title,
        subtitle,
        image,
        link
      };
      return res.status(201).json({ success: true, data: newBanner });
    }

    const newBanner = {
      id: Date.now(),
      title: title || 'New Collection',
      subtitle: subtitle || '',
      image: image || 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=1600&q=95',
      link: link || '/collections'
    };
    banners.unshift(newBanner);
    res.status(201).json({ success: true, data: newBanner });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.delete('/banners/:id', verifyAdmin, async (req, res) => {
  try {
    const bannerId = parseInt(req.params.id);

    if (db.useDb()) {
      const [result] = await db.pool().query('DELETE FROM banners WHERE id = ?', [bannerId]);
      if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Banner not found' });
      return res.json({ success: true, message: 'Banner deleted' });
    }

    banners = banners.filter(b => b.id !== bannerId);
    res.json({ success: true, message: 'Banner deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// SHOP CATEGORIES API (for Home page "Shop by Category" section)
router.get('/categories', async (req, res) => {
  try {
    if (db.useDb()) {
      const [rows] = await db.pool().query('SELECT * FROM categories');
      return res.json({ success: true, data: rows });
    }
    res.json({ success: true, data: shopCategories });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/categories', verifyAdmin, async (req, res) => {
  try {
    const { name, slug, image } = req.body;
    if (!name) return res.status(400).json({ success: false, message: 'Category name is required' });

    if (db.useDb()) {
      const catSlug = slug || name.toLowerCase().trim().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
      const [result] = await db.pool().query(`
        INSERT INTO categories (name, slug, image)
        VALUES (?, ?, ?)
      `, [
        name.trim(),
        catSlug,
        image || 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80'
      ]);

      const newCat = {
        id: result.insertId,
        name: name.trim(),
        slug: catSlug,
        image
      };
      return res.status(201).json({ success: true, data: newCat });
    }

    const newCat = {
      id: Date.now(),
      name: name.trim(),
      slug: slug || name.toLowerCase().trim().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, ''),
      image: image || 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80'
    };
    shopCategories.push(newCat);
    res.status(201).json({ success: true, data: newCat });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.put('/categories/:id', verifyAdmin, async (req, res) => {
  try {
    const catId = parseInt(req.params.id);

    if (db.useDb()) {
      const updates = { ...req.body };
      const fields = [];
      const params = [];

      for (const key of ['name', 'slug', 'image']) {
        if (updates[key] !== undefined) {
          fields.push(`${key} = ?`);
          params.push(updates[key]);
        }
      }

      if (fields.length > 0) {
        params.push(catId);
        await db.pool().query(`UPDATE categories SET ${fields.join(', ')} WHERE id = ?`, params);
      }

      const [rows] = await db.pool().query('SELECT * FROM categories WHERE id = ?', [catId]);
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'Category not found' });
      return res.json({ success: true, data: rows[0] });
    }

    const idx = shopCategories.findIndex(c => c.id === catId);
    if (idx === -1) return res.status(404).json({ success: false, message: 'Category not found' });
    shopCategories[idx] = { ...shopCategories[idx], ...req.body, id: catId };
    res.json({ success: true, data: shopCategories[idx] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.delete('/categories/:id', verifyAdmin, async (req, res) => {
  try {
    const catId = parseInt(req.params.id);

    if (db.useDb()) {
      const [result] = await db.pool().query('DELETE FROM categories WHERE id = ?', [catId]);
      if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Category not found' });
      return res.json({ success: true, message: 'Category deleted' });
    }

    shopCategories = shopCategories.filter(c => c.id !== catId);
    res.json({ success: true, message: 'Category deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
