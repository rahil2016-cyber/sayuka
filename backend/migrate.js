const db = require('./config/db');
const productsData = require('./data/products');

// Default initial banners
const defaultBanners = [
  {
    title: "Timeless Heritage Collection",
    subtitle: "Handcrafted gold plated 92.5 silver & Jadau sets",
    image: "https://images.unsplash.com/photo-1610694955371-d4a3e0ce4b52?w=1600&q=95",
    link: "/collections?category=gold-plated-necklace"
  },
  {
    title: "Modern CZ & Diamond Sparkle",
    subtitle: "Brilliant craftsmanship designed to shine for every occasion",
    image: "https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=1600&q=95",
    link: "/collections?category=cz"
  }
];

// Default initial categories
const defaultCategories = [
  // Fashion Jewellery
  { name: 'Necklaces', slug: 'necklaces', image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80' },
  { name: 'Earrings', slug: 'earrings', image: 'https://images.unsplash.com/photo-1635767798638-3e25273a8236?w=600&q=80' },
  { name: 'Pendant Sets', slug: 'pendant-sets', image: 'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=600&q=80' },
  { name: 'Bangles & Bracelets', slug: 'bangles-bracelets', image: 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=600&q=80' },
  { name: 'Rings', slug: 'rings', image: 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=600&q=80' },
  { name: 'Maangtika', slug: 'maangtika', image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=600&q=80' },
  { name: 'Matil', slug: 'matil', image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80' },
  { name: 'Brooch', slug: 'brooch', image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80' },
  { name: 'Hathpans', slug: 'hathpans', image: 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=600&q=80' },
  { name: 'Bajubandh', slug: 'bajubandh', image: 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=600&q=80' },
  { name: 'Belt', slug: 'belt', image: 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=600&q=80' },
  { name: 'Nath', slug: 'nath', image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=600&q=80' },

  // Collections
  { name: 'Antique', slug: 'antique', image: 'https://images.unsplash.com/photo-1610694955371-d4a3e0ce4b52?w=600&q=80' },
  { name: 'CZ', slug: 'cz', image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=600&q=80' },
  { name: 'Victorian', slug: 'victorian', image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80' },
  { name: 'Jadau', slug: 'jadau', image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=600&q=80' },
  { name: 'Pearls', slug: 'pearls', image: 'https://images.unsplash.com/photo-1635767798638-3e25273a8236?w=600&q=80' },
  { name: 'Mangalsutra', slug: 'mangalsutra', image: 'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=600&q=80' },
  { name: 'Mother of Pearl', slug: 'mother-of-pearl', image: 'https://images.unsplash.com/photo-1635767798638-3e25273a8236?w=600&q=80' },
  { name: 'Anti-Tarnish', slug: 'anti-tarnish', image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80' },

  // Gold Plated 92.5 Silver Jewellery
  { name: 'Gold-Plated Necklace', slug: 'gold-plated-necklace', image: 'https://images.unsplash.com/photo-1610694955371-d4a3e0ce4b52?w=600&q=80' },
  { name: 'Gold-Plated Earrings', slug: 'gold-plated-earrings', image: 'https://images.unsplash.com/photo-1635767798638-3e25273a8236?w=600&q=80' },
  { name: 'Gold-Plated Pendant Sets', slug: 'gold-plated-pendant-sets', image: 'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=600&q=80' },
  { name: 'Gold-Plated Bracelets', slug: 'gold-plated-bracelets', image: 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=600&q=80' },
  { name: 'Gold-Plated Accessories', slug: 'gold-plated-accessories', image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=600&q=80' },
  { name: 'Gold-Plated Rings', slug: 'gold-plated-rings', image: 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=600&q=80' },
  { name: 'Gold-Plated Chains', slug: 'gold-plated-chains', image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80' },

  // 92.5 Silver Jewellery
  { name: 'Silver Earrings', slug: 'silver-earrings', image: 'https://images.unsplash.com/photo-1635767798638-3e25273a8236?w=600&q=80' },
  { name: 'Silver Chains', slug: 'silver-chains', image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80' },
  { name: 'Silver Pendant Sets', slug: 'silver-pendant-sets', image: 'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=600&q=80' },
  { name: 'Silver Bracelets', slug: 'silver-bracelets', image: 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=600&q=80' },
  { name: 'Silver Rings', slug: 'silver-rings', image: 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=600&q=80' },
  { name: 'Silver Toe rings', slug: 'silver-toe-rings', image: 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=600&q=80' },
  { name: 'Silver Accessories', slug: 'silver-accessories', image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=600&q=80' }
];

async function migrate(shouldExit = false) {
  console.log('🔄 Starting Database Schema Creation...');

  const connection = await db.getConnection();

  try {
    // 1. Create Tables
    await connection.query(`
      CREATE TABLE IF NOT EXISTS categories (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        slug VARCHAR(255) UNIQUE NOT NULL,
        image LONGTEXT NULL
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);
    console.log('✅ Categories table created/verified.');

    await connection.query(`
      CREATE TABLE IF NOT EXISTS products (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        slug VARCHAR(255) UNIQUE NOT NULL,
        price DECIMAL(10, 2) NOT NULL,
        original_price DECIMAL(10, 2) NULL,
        description TEXT NULL,
        images JSON NOT NULL,
        stock INT DEFAULT 10,
        in_stock TINYINT(1) DEFAULT 1,
        is_featured TINYINT(1) DEFAULT 0,
        is_bestseller TINYINT(1) DEFAULT 0,
        rating DECIMAL(3, 2) DEFAULT 5.00,
        reviews INT DEFAULT 0,
        collection VARCHAR(100) NULL,
        type VARCHAR(100) NULL,
        material VARCHAR(255) NULL,
        gemstone VARCHAR(255) NULL,
        weight VARCHAR(100) NULL,
        badge VARCHAR(100) NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);
    console.log('✅ Products table created/verified.');

    await connection.query(`
      CREATE TABLE IF NOT EXISTS product_categories (
        product_id INT NOT NULL,
        category_id INT NOT NULL,
        PRIMARY KEY (product_id, category_id),
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);
    console.log('✅ Product_Categories bridge table created/verified.');

    await connection.query(`
      CREATE TABLE IF NOT EXISTS banners (
        id INT AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        subtitle VARCHAR(255) NULL,
        image LONGTEXT NOT NULL,
        link VARCHAR(255) DEFAULT '/collections',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);
    console.log('✅ Banners table created/verified.');

    // Alter existing tables if they were previously created with VARCHAR(255)
    try {
      await connection.query('ALTER TABLE banners MODIFY COLUMN image LONGTEXT NOT NULL');
      await connection.query('ALTER TABLE categories MODIFY COLUMN image LONGTEXT NULL');
      console.log('✅ Column types modified to LONGTEXT successfully.');
    } catch (alterErr) {
      console.warn('⚠️ Column alteration warning (might already be LONGTEXT):', alterErr.message);
    }

    await connection.query(`
      CREATE TABLE IF NOT EXISTS orders (
        id VARCHAR(50) PRIMARY KEY,
        customer_name VARCHAR(255) NOT NULL,
        customer_email VARCHAR(255) NOT NULL,
        customer_phone VARCHAR(50) NOT NULL,
        whatsapp_consent TINYINT(1) DEFAULT 0,
        shipping_address TEXT NOT NULL,
        total_amount DECIMAL(10, 2) NOT NULL,
        order_status VARCHAR(50) DEFAULT 'Pending',
        payment_status VARCHAR(50) DEFAULT 'Pending',
        payment_method VARCHAR(50) NULL,
        payment_gateway VARCHAR(50) NULL,
        payment_order_id VARCHAR(100) UNIQUE NULL,
        payment_transaction_id VARCHAR(100) UNIQUE NULL,
        payment_signature VARCHAR(255) NULL,
        paid_at TIMESTAMP NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);
    console.log('✅ Orders table created/verified.');

    await connection.query(`
      CREATE TABLE IF NOT EXISTS order_items (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_id VARCHAR(50) NOT NULL,
        product_id INT NULL,
        product_name VARCHAR(255) NOT NULL,
        price DECIMAL(10, 2) NOT NULL,
        qty INT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);
    console.log('✅ Order_Items table created/verified.');

    await connection.query(`
      CREATE TABLE IF NOT EXISTS webhook_logs (
        event_id VARCHAR(100) PRIMARY KEY,
        gateway VARCHAR(50) NOT NULL,
        order_id VARCHAR(50) NOT NULL,
        processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);
    console.log('✅ Webhook_Logs table created/verified.');

    // 2. Seed Categories (Idempotent)
    console.log('🌱 Seeding Categories...');
    for (const cat of defaultCategories) {
      await connection.query(`
        INSERT INTO categories (name, slug, image)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE name = VALUES(name), image = VALUES(image)
      `, [cat.name, cat.slug, cat.image]);
    }

    // 3. Seed Banners (Idempotent)
    console.log('🌱 Seeding Banners...');
    for (const banner of defaultBanners) {
      const [rows] = await connection.query('SELECT id FROM banners WHERE title = ?', [banner.title]);
      if (rows.length === 0) {
        await connection.query(`
          INSERT INTO banners (title, subtitle, image, link)
          VALUES (?, ?, ?, ?)
        `, [banner.title, banner.subtitle, banner.image, banner.link]);
      } else {
        await connection.query(`
          UPDATE banners SET subtitle = ?, image = ?, link = ? WHERE title = ?
        `, [banner.subtitle, banner.image, banner.link, banner.title]);
      }
    }

    // 4. Seed Products (Idempotent)
    console.log('🌱 Seeding Products...');
    for (const prod of productsData) {
      const slug = prod.slug || prod.name.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
      const imagesJson = JSON.stringify(prod.images || [prod.image]);

      const [prodRows] = await connection.query('SELECT id FROM products WHERE slug = ?', [slug]);
      let productId;

      if (prodRows.length === 0) {
        const [result] = await connection.query(`
          INSERT INTO products (name, slug, price, original_price, description, images, stock, in_stock, is_featured, is_bestseller, rating, reviews, collection, type, material, gemstone, weight, badge)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `, [
          prod.name,
          slug,
          prod.price,
          prod.originalPrice || prod.price,
          prod.description || '',
          imagesJson,
          prod.stock || 10,
          prod.inStock !== false ? 1 : 0,
          prod.isFeatured ? 1 : 0,
          prod.isBestseller ? 1 : 0,
          prod.rating || 5.0,
          prod.reviews || 0,
          prod.collection || null,
          prod.type || null,
          prod.material || null,
          prod.gemstone || null,
          prod.weight || null,
          prod.badge || null
        ]);
        productId = result.insertId;
      } else {
        productId = prodRows[0].id;
        await connection.query(`
          UPDATE products
          SET name = ?, price = ?, original_price = ?, description = ?, images = ?, stock = ?, in_stock = ?, is_featured = ?, is_bestseller = ?, collection = ?, type = ?, material = ?, gemstone = ?, weight = ?, badge = ?
          WHERE id = ?
        `, [
          prod.name,
          prod.price,
          prod.originalPrice || prod.price,
          prod.description || '',
          imagesJson,
          prod.stock || 10,
          prod.inStock !== false ? 1 : 0,
          prod.isFeatured ? 1 : 0,
          prod.isBestseller ? 1 : 0,
          prod.collection || null,
          prod.type || null,
          prod.material || null,
          prod.gemstone || null,
          prod.weight || null,
          prod.badge || null,
          productId
        ]);
      }

      const categoriesToLink = prod.categories || (prod.category ? [prod.category] : ['necklaces']);
      for (const catSlug of categoriesToLink) {
        const [catRows] = await connection.query('SELECT id FROM categories WHERE slug = ?', [catSlug]);
        if (catRows.length > 0) {
          const categoryId = catRows[0].id;
          await connection.query(`
            INSERT IGNORE INTO product_categories (product_id, category_id)
            VALUES (?, ?)
          `, [productId, categoryId]);
        }
      }
    }

    console.log('🎉 Database migration & seeding completed successfully!');
  } catch (err) {
    console.error('❌ Migration failed:', err);
  } finally {
    connection.release();
    if (shouldExit) {
      process.exit();
    }
  }
}

if (require.main === module) {
  migrate(true);
}

module.exports = migrate;
