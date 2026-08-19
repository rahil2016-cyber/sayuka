const express = require('express');
const router = express.Router();
let products = require('../data/products');
const verifyAdmin = require('../middleware/auth');
const db = require('../config/db');

// Get all products with optional filters
router.get('/', async (req, res) => {
  try {
    if (db.useDb()) {
      let query = `
        SELECT p.*, GROUP_CONCAT(c.slug) as categories_list 
        FROM products p 
        LEFT JOIN product_categories pc ON p.id = pc.product_id 
        LEFT JOIN categories c ON pc.category_id = c.id
      `;
      let conditions = [];
      let params = [];

      const { category, subcategory, collection, type, minPrice, maxPrice, sort, search } = req.query;

      if (category && category !== 'all') {
        conditions.push('(c.slug = ? OR p.type = ?)');
        params.push(category, category);
      }
      if (subcategory) {
        conditions.push('p.subcategory = ?');
        params.push(subcategory);
      }
      if (collection) {
        conditions.push('p.collection = ?');
        params.push(collection);
      }
      if (type) {
        conditions.push('p.type = ?');
        params.push(type);
      }
      if (minPrice) {
        conditions.push('p.price >= ?');
        params.push(parseFloat(minPrice));
      }
      if (maxPrice) {
        conditions.push('p.price <= ?');
        params.push(parseFloat(maxPrice));
      }
      if (search) {
        conditions.push('(p.name LIKE ? OR p.description LIKE ? OR p.material LIKE ?)');
        const wildcard = `%${search}%`;
        params.push(wildcard, wildcard, wildcard);
      }

      if (conditions.length > 0) {
        query += ' WHERE ' + conditions.join(' AND ');
      }

      query += ' GROUP BY p.id';

      if (sort === 'price_asc') {
        query += ' ORDER BY p.price ASC';
      } else if (sort === 'price_desc') {
        query += ' ORDER BY p.price DESC';
      } else if (sort === 'rating') {
        query += ' ORDER BY p.rating DESC';
      }

      const [rows] = await db.pool().query(query, params);
      
      const formatted = rows.map(r => ({
        ...r,
        price: parseFloat(r.price),
        originalPrice: r.original_price ? parseFloat(r.original_price) : parseFloat(r.price),
        inStock: !!r.in_stock,
        isFeatured: !!r.is_featured,
        isBestseller: !!r.is_bestseller,
        rating: parseFloat(r.rating),
        images: typeof r.images === 'string' ? JSON.parse(r.images) : r.images,
        categories: r.categories_list ? r.categories_list.split(',') : []
      }));

      return res.json({ success: true, count: formatted.length, data: formatted });
    }

    // In-memory fallback
    let filtered = [...products];
    const { category, subcategory, collection, type, minPrice, maxPrice, sort, search } = req.query;

    if (category && category !== 'all') {
      filtered = filtered.filter(p => p.category === category || p.type === category);
    }
    if (subcategory) {
      filtered = filtered.filter(p => p.subcategory === subcategory);
    }
    if (collection) {
      filtered = filtered.filter(p => p.collection === collection);
    }
    if (type) {
      filtered = filtered.filter(p => p.type === type);
    }
    if (minPrice) {
      filtered = filtered.filter(p => p.price >= parseFloat(minPrice));
    }
    if (maxPrice) {
      filtered = filtered.filter(p => p.price <= parseFloat(maxPrice));
    }
    if (search) {
      const q = search.toLowerCase().trim();
      filtered = filtered.filter(p =>
        p.name.toLowerCase().includes(q) ||
        p.category.toLowerCase().includes(q) ||
        (p.collection && p.collection.toLowerCase().includes(q)) ||
        (p.material && p.material.toLowerCase().includes(q)) ||
        (p.description && p.description.toLowerCase().includes(q))
      );
    }

    if (sort === 'price_asc') {
      filtered.sort((a, b) => a.price - b.price);
    } else if (sort === 'price_desc') {
      filtered.sort((a, b) => b.price - a.price);
    } else if (sort === 'rating') {
      filtered.sort((a, b) => b.rating - a.rating);
    }

    res.json({ success: true, count: filtered.length, data: filtered });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Get bestsellers
router.get('/bestsellers', async (req, res) => {
  try {
    if (db.useDb()) {
      const [rows] = await db.pool().query('SELECT * FROM products WHERE is_bestseller = 1');
      const formatted = rows.map(r => ({
        ...r,
        price: parseFloat(r.price),
        originalPrice: r.original_price ? parseFloat(r.original_price) : parseFloat(r.price),
        inStock: !!r.in_stock,
        isFeatured: !!r.is_featured,
        isBestseller: !!r.is_bestseller,
        rating: parseFloat(r.rating),
        images: typeof r.images === 'string' ? JSON.parse(r.images) : r.images
      }));
      return res.json({ success: true, data: formatted });
    }

    const bestsellers = products.filter(p => p.isBestseller);
    res.json({ success: true, data: bestsellers });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Create product (Admin)
router.post('/', verifyAdmin, async (req, res) => {
  try {
    const { name, slug, description, price, originalPrice, categories, isFeatured, isBestseller, stock, image, collection, type, material, gemstone, weight, badge } = req.body;
    
    if (db.useDb()) {
      const productSlug = slug || name.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
      const imagesJson = JSON.stringify([image || 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80']);

      const [result] = await db.pool().query(`
        INSERT INTO products (name, slug, price, original_price, description, images, stock, in_stock, is_featured, is_bestseller, rating, reviews, collection, type, material, gemstone, weight, badge)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 5.0, 1, ?, ?, ?, ?, ?, ?)
      `, [
        name,
        productSlug,
        parseFloat(price) || 0,
        parseFloat(originalPrice) || parseFloat(price) || 0,
        description || '',
        imagesJson,
        parseInt(stock) || 10,
        (stock !== undefined ? parseInt(stock) > 0 : true) ? 1 : 0,
        isFeatured ? 1 : 0,
        isBestseller ? 1 : 0,
        collection || null,
        type || null,
        material || null,
        gemstone || null,
        weight || null,
        badge || null
      ]);

      const newProductId = result.insertId;

      // Insert categories link
      const linkCats = categories || ['necklaces'];
      for (const catSlug of linkCats) {
        const [catRows] = await db.pool().query('SELECT id FROM categories WHERE slug = ?', [catSlug]);
        if (catRows.length > 0) {
          await db.pool().query('INSERT IGNORE INTO product_categories (product_id, category_id) VALUES (?, ?)', [newProductId, catRows[0].id]);
        }
      }

      const [newProdRows] = await db.pool().query('SELECT * FROM products WHERE id = ?', [newProductId]);
      const newProd = {
        ...newProdRows[0],
        price: parseFloat(newProdRows[0].price),
        originalPrice: parseFloat(newProdRows[0].original_price),
        images: JSON.parse(newProdRows[0].images),
        categories: linkCats
      };

      return res.status(201).json({ success: true, data: newProd });
    }

    // In-memory fallback
    const newProduct = {
      id: Date.now(),
      name: name || 'New Product',
      slug: slug || 'new-product',
      price: parseFloat(price) || 0,
      originalPrice: parseFloat(originalPrice) || parseFloat(price) || 0,
      category: Array.isArray(categories) && categories[0] ? categories[0] : 'necklaces',
      categories: categories || ['necklaces'],
      description: description || '',
      images: [image || 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80'],
      inStock: (stock !== undefined ? parseInt(stock) > 0 : true),
      stock: parseInt(stock) || 10,
      isFeatured: !!isFeatured,
      isBestseller: !!isBestseller,
      rating: 5.0,
      reviews: 1
    };
    products.unshift(newProduct);
    res.status(201).json({ success: true, data: newProduct });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Update product (Admin)
router.put('/:id', verifyAdmin, async (req, res) => {
  try {
    const id = parseInt(req.params.id);

    if (db.useDb()) {
      const updates = { ...req.body };
      const fields = [];
      const params = [];

      if (updates.image) {
        updates.images = JSON.stringify([updates.image]);
        delete updates.image;
      }

      const allowedFields = [
        'name', 'slug', 'price', 'originalPrice', 'description', 'images', 'stock', 
        'inStock', 'isFeatured', 'isBestseller', 'collection', 'type', 'material', 
        'gemstone', 'weight', 'badge'
      ];

      for (const key of Object.keys(updates)) {
        if (allowedFields.includes(key)) {
          let dbKey = key;
          if (key === 'originalPrice') dbKey = 'original_price';
          if (key === 'inStock') {
            dbKey = 'in_stock';
            updates[key] = updates[key] ? 1 : 0;
          }
          if (key === 'isFeatured') {
            dbKey = 'is_featured';
            updates[key] = updates[key] ? 1 : 0;
          }
          if (key === 'isBestseller') {
            dbKey = 'is_bestseller';
            updates[key] = updates[key] ? 1 : 0;
          }
          fields.push(`${dbKey} = ?`);
          params.push(updates[key]);
        }
      }

      if (fields.length > 0) {
        params.push(id);
        await db.pool().query(`UPDATE products SET ${fields.join(', ')} WHERE id = ?`, params);
      }

      if (updates.categories) {
        await db.pool().query('DELETE FROM product_categories WHERE product_id = ?', [id]);
        for (const catSlug of updates.categories) {
          const [catRows] = await db.pool().query('SELECT id FROM categories WHERE slug = ?', [catSlug]);
          if (catRows.length > 0) {
            await db.pool().query('INSERT IGNORE INTO product_categories (product_id, category_id) VALUES (?, ?)', [id, catRows[0].id]);
          }
        }
      }

      const [rows] = await db.pool().query('SELECT * FROM products WHERE id = ?', [id]);
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'Product not found' });
      
      const updatedProd = {
        ...rows[0],
        price: parseFloat(rows[0].price),
        originalPrice: parseFloat(rows[0].original_price),
        images: JSON.parse(rows[0].images)
      };
      return res.json({ success: true, data: updatedProd });
    }

    const index = products.findIndex(p => p.id === id);
    if (index === -1) return res.status(404).json({ success: false, message: 'Product not found' });

    products[index] = { ...products[index], ...req.body };
    res.json({ success: true, data: products[index] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Delete product (Admin)
router.delete('/:id', verifyAdmin, async (req, res) => {
  try {
    const id = parseInt(req.params.id);

    if (db.useDb()) {
      const [result] = await db.pool().query('DELETE FROM products WHERE id = ?', [id]);
      if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Product not found' });
      return res.json({ success: true, message: 'Product deleted successfully' });
    }

    products = products.filter(p => p.id !== id);
    res.json({ success: true, message: 'Product deleted successfully' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Get single product by ID
router.get('/:id', async (req, res) => {
  try {
    const id = parseInt(req.params.id);

    if (db.useDb()) {
      const [rows] = await db.pool().query(`
        SELECT p.*, GROUP_CONCAT(c.slug) as categories_list 
        FROM products p 
        LEFT JOIN product_categories pc ON p.id = pc.product_id 
        LEFT JOIN categories c ON pc.category_id = c.id
        WHERE p.id = ?
        GROUP BY p.id
      `, [id]);
      
      if (rows.length === 0) {
        return res.status(404).json({ success: false, message: 'Product not found' });
      }
      
      const formatted = {
        ...rows[0],
        price: parseFloat(rows[0].price),
        originalPrice: rows[0].original_price ? parseFloat(rows[0].original_price) : parseFloat(rows[0].price),
        inStock: !!rows[0].in_stock,
        isFeatured: !!rows[0].is_featured,
        isBestseller: !!rows[0].is_bestseller,
        rating: parseFloat(rows[0].rating),
        images: typeof rows[0].images === 'string' ? JSON.parse(rows[0].images) : rows[0].images,
        categories: rows[0].categories_list ? rows[0].categories_list.split(',') : []
      };
      
      return res.json({ success: true, data: formatted });
    }

    const product = products.find(p => p.id === id);
    if (!product) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }
    res.json({ success: true, data: product });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
