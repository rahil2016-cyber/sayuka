const express = require('express');
const router = express.Router();
let products = require('../data/products');

// Get all products with optional filters
router.get('/', (req, res) => {
  try {
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
router.get('/bestsellers', (req, res) => {
  try {
    const bestsellers = products.filter(p => p.isBestseller);
    res.json({ success: true, data: bestsellers });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Create product (Admin)
router.post('/', (req, res) => {
  try {
    const { name, slug, description, price, originalPrice, categories, isFeatured, isBestseller, stock, image } = req.body;
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
router.put('/:id', (req, res) => {
  try {
    const id = parseInt(req.params.id);
    const index = products.findIndex(p => p.id === id);
    if (index === -1) return res.status(404).json({ success: false, message: 'Product not found' });

    products[index] = { ...products[index], ...req.body };
    res.json({ success: true, data: products[index] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Delete product (Admin)
router.delete('/:id', (req, res) => {
  try {
    const id = parseInt(req.params.id);
    products = products.filter(p => p.id !== id);
    res.json({ success: true, message: 'Product deleted successfully' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Get single product by ID
router.get('/:id', (req, res) => {
  try {
    const product = products.find(p => p.id === parseInt(req.params.id));
    if (!product) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }
    res.json({ success: true, data: product });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
