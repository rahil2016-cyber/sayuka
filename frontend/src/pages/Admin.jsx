import React, { useState, useEffect } from 'react';
import { productsAPI, adminAPI } from '../api';
import { categoryStructure } from '../data/categoriesData';
import './Admin.css';

const Admin = () => {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [products, setProducts] = useState([]);
  const [orders, setOrders] = useState([]);
  const [banners, setBanners] = useState([]);
  const [shopCategories, setShopCategories] = useState([]);
  const [loading, setLoading] = useState(true);

  // Modal States
  const [productModalOpen, setProductModalOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState(null);
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [bannerModalOpen, setBannerModalOpen] = useState(false);
  const [categoryModalOpen, setCategoryModalOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState(null);

  // Form States
  const [productForm, setProductForm] = useState({
    name: '',
    slug: '',
    description: '',
    price: '',
    originalPrice: '',
    categories: ['necklaces'],
    stock: 10,
    isFeatured: false,
    isBestseller: false,
    image: ''
  });

  const [bannerForm, setBannerForm] = useState({
    title: '',
    subtitle: '',
    image: '',
    link: '/collections'
  });

  const [categoryForm, setCategoryForm] = useState({
    name: '',
    slug: '',
    image: ''
  });

  useEffect(() => {
    loadAdminData();
  }, []);

  const loadAdminData = async () => {
    setLoading(true);
    try {
      const [prodRes, orderRes, bannerRes, catRes] = await Promise.all([
        productsAPI.getAll(),
        adminAPI.getOrders().catch(() => ({ data: { data: [] } })),
        adminAPI.getBanners().catch(() => ({ data: { data: [] } })),
        adminAPI.getCategories().catch(() => ({ data: { data: [] } }))
      ]);
      setProducts(prodRes.data.data || []);
      setOrders(orderRes.data.data || []);
      setBanners(bannerRes.data.data || []);
      setShopCategories(catRes.data.data || []);
    } catch (err) {
      console.error("Error loading admin data:", err);
    } finally {
      setLoading(false);
    }
  };

  // Product Actions
  const handleOpenProductModal = (product = null) => {
    if (product) {
      setEditingProduct(product);
      setProductForm({
        name: product.name,
        slug: product.slug || product.name.toLowerCase().replace(/\s+/g, '-'),
        description: product.description || '',
        price: product.price,
        originalPrice: product.originalPrice || product.price,
        categories: [product.category || 'necklaces'],
        stock: product.stock || 10,
        isFeatured: !!product.isFeatured,
        isBestseller: !!product.isBestseller,
        image: product.images ? product.images[0] : ''
      });
    } else {
      setEditingProduct(null);
      setProductForm({
        name: '',
        slug: '',
        description: '',
        price: '',
        originalPrice: '',
        categories: ['necklaces'],
        stock: 10,
        isFeatured: false,
        isBestseller: false,
        image: ''
      });
    }
    setProductModalOpen(true);
  };

  const handleSaveProduct = async (e) => {
    e.preventDefault();
    try {
      if (editingProduct) {
        await productsAPI.update(editingProduct.id, productForm);
      } else {
        await productsAPI.create(productForm);
      }
      setProductModalOpen(false);
      loadAdminData();
    } catch (err) {
      alert("Failed to save product: " + err.message);
    }
  };

  const handleDeleteProduct = async (id) => {
    if (window.confirm("Are you sure you want to delete this product?")) {
      try {
        await productsAPI.delete(id);
        loadAdminData();
      } catch (err) {
        alert("Failed to delete product");
      }
    }
  };

  // Order Actions
  const handleUpdateOrderStatus = async (orderId, newStatus) => {
    try {
      await adminAPI.updateOrderStatus(orderId, newStatus);
      if (selectedOrder && selectedOrder.id === orderId) {
        setSelectedOrder(prev => ({ ...prev, orderStatus: newStatus }));
      }
      loadAdminData();
    } catch (err) {
      alert("Failed to update status");
    }
  };

  // Banner Actions
  const handleCreateBanner = async (e) => {
    e.preventDefault();
    try {
      await adminAPI.createBanner(bannerForm);
      setBannerModalOpen(false);
      setBannerForm({ title: '', subtitle: '', image: '', link: '/collections' });
      loadAdminData();
    } catch (err) {
      console.error("Error creating banner:", err);
      alert("Failed to create banner: " + (err.response?.data?.message || err.message));
    }
  };

  const handleDeleteBanner = async (id) => {
    if (window.confirm("Delete this banner?")) {
      try {
        await adminAPI.deleteBanner(id);
        loadAdminData();
      } catch (err) {
        alert("Failed to delete banner");
      }
    }
  };

  // Category Actions
  const handleOpenCategoryModal = (cat = null) => {
    if (cat) {
      setEditingCategory(cat);
      setCategoryForm({ name: cat.name, slug: cat.slug, image: cat.image || '' });
    } else {
      setEditingCategory(null);
      setCategoryForm({ name: '', slug: '', image: '' });
    }
    setCategoryModalOpen(true);
  };

  const handleSaveCategory = async (e) => {
    e.preventDefault();
    try {
      if (editingCategory) {
        await adminAPI.updateCategory(editingCategory.id, categoryForm);
      } else {
        await adminAPI.createCategory(categoryForm);
      }
      setCategoryModalOpen(false);
      setCategoryForm({ name: '', slug: '', image: '' });
      setEditingCategory(null);
      loadAdminData();
    } catch (err) {
      alert("Failed to save category: " + (err.response?.data?.message || err.message));
    }
  };

  const handleDeleteCategory = async (id) => {
    if (window.confirm("Delete this category from the home page?")) {
      try {
        await adminAPI.deleteCategory(id);
        loadAdminData();
      } catch (err) {
        alert("Failed to delete category");
      }
    }
  };

  const totalSales = orders.reduce((acc, o) => acc + (o.totalAmount || 0), 0);


  return (
    <div className="admin-container">
      {/* Sidebar Navigation */}
      <aside className="admin-sidebar">
        <div className="admin-brand">
          <img src="/images/sayuka-logo.png" alt="Sayuka Admin" className="admin-logo-img" style={{ maxHeight: '50px', width: 'auto' }} />
          <span className="admin-panel-tag">Admin Panel</span>
        </div>

        <nav className="admin-nav-menu">
          <button
            className={`admin-nav-item ${activeTab === 'dashboard' ? 'active' : ''}`}
            onClick={() => setActiveTab('dashboard')}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="14" y="14" width="7" height="7" /><rect x="3" y="14" width="7" height="7" /></svg>
            <span>Dashboard</span>
          </button>

          <button
            className={`admin-nav-item ${activeTab === 'products' ? 'active' : ''}`}
            onClick={() => setActiveTab('products')}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" /></svg>
            <span>Products</span>
          </button>

          <button
            className={`admin-nav-item ${activeTab === 'orders' ? 'active' : ''}`}
            onClick={() => setActiveTab('orders')}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="9" cy="21" r="1" /><circle cx="20" cy="21" r="1" /><path d="M1 1h4l2.68 13.39a2 2 0 002 1.61h9.72a2 2 0 002-1.61L23 6H6" /></svg>
            <span>Orders</span>
          </button>

          <button
            className={`admin-nav-item ${activeTab === 'categories' ? 'active' : ''}`}
            onClick={() => setActiveTab('categories')}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z" /></svg>
            <span>Categories</span>
          </button>

          <button
            className={`admin-nav-item ${activeTab === 'banners' ? 'active' : ''}`}
            onClick={() => setActiveTab('banners')}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="3" width="18" height="18" rx="2" ry="2" /><circle cx="8.5" cy="8.5" r="1.5" /><polyline points="21 15 16 10 5 21" /></svg>
            <span>Banners</span>
          </button>

          <a href="/" className="admin-nav-item logout">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4" /><polyline points="16 17 21 12 16 7" /><line x1="21" y1="12" x2="9" y2="12" /></svg>
            <span>Exit Admin</span>
          </a>
        </nav>
      </aside>

      {/* Main Admin Content */}
      <main className="admin-main-content">
        {loading ? (
          <div className="admin-loading">Loading Dashboard...</div>
        ) : (
          <>
            {/* 1. DASHBOARD OVERVIEW TAB */}
            {activeTab === 'dashboard' && (
              <div className="admin-tab-content">
                <header className="admin-header">
                  <div>
                    <h1 className="admin-page-title">Dashboard Overview</h1>
                    <p className="admin-subtitle">Welcome back, Admin!</p>
                  </div>
                </header>

                {/* Stats Cards */}
                <div className="stats-cards-grid">
                  <div className="stat-card">
                    <div className="stat-info">
                      <span className="stat-label">Total Sales</span>
                      <h2 className="stat-value">₹{totalSales.toFixed(2)}</h2>
                    </div>
                    <div className="stat-icon icon-green">$</div>
                  </div>

                  <div className="stat-card">
                    <div className="stat-info">
                      <span className="stat-label">Total Orders</span>
                      <h2 className="stat-value">{orders.length}</h2>
                    </div>
                    <div className="stat-icon icon-blue">
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="9" cy="21" r="1" /><circle cx="20" cy="21" r="1" /><path d="M1 1h4l2.68 13.39a2 2 0 002 1.61h9.72a2 2 0 002-1.61L23 6H6" /></svg>
                    </div>
                  </div>

                  <div className="stat-card">
                    <div className="stat-info">
                      <span className="stat-label">Products</span>
                      <h2 className="stat-value">{products.length}</h2>
                    </div>
                    <div className="stat-icon icon-purple">
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" /></svg>
                    </div>
                  </div>

                  <div className="stat-card">
                    <div className="stat-info">
                      <span className="stat-label">Customers</span>
                      <h2 className="stat-value">12</h2>
                    </div>
                    <div className="stat-icon icon-orange">
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2" /><circle cx="9" cy="7" r="4" /></svg>
                    </div>
                  </div>
                </div>

                {/* Dashboard Split Views */}
                <div className="dashboard-split-grid">
                  {/* Recent Orders */}
                  <div className="admin-card">
                    <div className="admin-card-header">
                      <h3>Recent Orders</h3>
                      <button className="view-all-link" onClick={() => setActiveTab('orders')}>View All</button>
                    </div>
                    <div className="orders-list">
                      {orders.map(order => (
                        <div key={order.id} className="order-list-item">
                          <div>
                            <div className="order-item-id">{order.id}</div>
                            <div className="order-customer-name">{order.customer.name}</div>
                          </div>
                          <div className="order-item-right">
                            <div className="order-price">₹{order.totalAmount.toFixed(2)}</div>
                            <span className={`status-badge status-${order.orderStatus.toLowerCase()}`}>
                              {order.orderStatus}
                            </span>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Recent Products & Offers */}
                  <div className="admin-card">
                    <div className="admin-card-header">
                      <h3>Recent Products &amp; Offers</h3>
                      <button className="btn btn-primary btn-sm" onClick={() => handleOpenProductModal()}>+ Add Product</button>
                    </div>
                    <table className="admin-table">
                      <thead>
                        <tr>
                          <th>PRODUCT</th>
                          <th>PRICE</th>
                          <th>ACTIONS</th>
                        </tr>
                      </thead>
                      <tbody>
                        {products.slice(0, 5).map(prod => (
                          <tr key={prod.id}>
                            <td className="product-table-cell">
                              <img src={prod.images ? prod.images[0] : ''} alt={prod.name} className="table-thumb" />
                              <span>{prod.name}</span>
                            </td>
                            <td>₹{prod.price}</td>
                            <td>
                              <button className="table-icon-btn" onClick={() => handleOpenProductModal(prod)}>✏️</button>
                              <button className="table-icon-btn danger" onClick={() => handleDeleteProduct(prod.id)}>🗑️</button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            )}

            {/* 2. PRODUCTS TAB */}
            {activeTab === 'products' && (
              <div className="admin-tab-content">
                <header className="admin-header">
                  <div>
                    <h1 className="admin-page-title">Products</h1>
                    <p className="admin-subtitle">Manage your product inventory, prices, and stock</p>
                  </div>
                  <button className="btn btn-primary" onClick={() => handleOpenProductModal()}>
                    + Add Product
                  </button>
                </header>

                <div className="admin-card">
                  <table className="admin-table full">
                    <thead>
                      <tr>
                        <th>PRODUCT</th>
                        <th>CATEGORY</th>
                        <th>PRICE</th>
                        <th>STOCK</th>
                        <th>ACTIONS</th>
                      </tr>
                    </thead>
                    <tbody>
                      {products.map(prod => (
                        <tr key={prod.id}>
                          <td className="product-table-cell">
                            <img src={prod.images ? prod.images[0] : ''} alt={prod.name} className="table-thumb" />
                            <div>
                              <div className="table-prod-name">{prod.name}</div>
                              <div className="table-prod-sub">{prod.material}</div>
                            </div>
                          </td>
                          <td><span className="cat-chip">{prod.category}</span></td>
                          <td><strong>₹{prod.price}</strong></td>
                          <td>
                            <span className={`stock-badge ${prod.inStock !== false ? 'in-stock' : 'out-stock'}`}>
                              {prod.stock || 10} In Stock
                            </span>
                          </td>
                          <td>
                            <button className="table-action-btn edit" onClick={() => handleOpenProductModal(prod)}>Edit</button>
                            <button className="table-action-btn delete" onClick={() => handleDeleteProduct(prod.id)}>Delete</button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* 3. ORDERS TAB */}
            {activeTab === 'orders' && (
              <div className="admin-tab-content">
                <header className="admin-header">
                  <div>
                    <h1 className="admin-page-title">Orders</h1>
                    <p className="admin-subtitle">View and manage customer orders and shipping status</p>
                  </div>
                </header>

                <div className="admin-card">
                  <table className="admin-table full">
                    <thead>
                      <tr>
                        <th>ORDER ID</th>
                        <th>CUSTOMER</th>
                        <th>TOTAL</th>
                        <th>STATUS</th>
                        <th>ACTIONS</th>
                      </tr>
                    </thead>
                    <tbody>
                      {orders.map(order => (
                        <tr key={order.id}>
                          <td><strong>{order.id}</strong></td>
                          <td>
                            <div>{order.customer.name}</div>
                            <div className="table-sub-text">{order.customer.phone}</div>
                          </td>
                          <td><strong>₹{order.totalAmount.toFixed(2)}</strong></td>
                          <td>
                            <span className={`status-badge status-${order.orderStatus.toLowerCase()}`}>
                              {order.orderStatus}
                            </span>
                          </td>
                          <td>
                            <button className="table-action-btn view" onClick={() => setSelectedOrder(order)}>👁️ View</button>
                            <select
                              value={order.orderStatus}
                              onChange={(e) => handleUpdateOrderStatus(order.id, e.target.value)}
                              className="order-select-status"
                            >
                              <option value="Pending">Pending</option>
                              <option value="Processing">Processing</option>
                              <option value="Shipped">Shipped</option>
                              <option value="Delivered">Delivered</option>
                              <option value="Cancelled">Cancelled</option>
                            </select>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* 4. CATEGORIES TAB */}
            {activeTab === 'categories' && (
              <div className="admin-tab-content">
                <header className="admin-header">
                  <div>
                    <h1 className="admin-page-title">Shop Categories</h1>
                    <p className="admin-subtitle">Manage the "Shop by Category" section displayed on the Home page</p>
                  </div>
                  <button className="btn btn-primary" onClick={() => handleOpenCategoryModal()}>
                    + Add Category
                  </button>
                </header>

                {/* Category Cards Grid */}
                <div className="category-admin-grid">
                  {shopCategories.map(cat => (
                    <div key={cat.id} className="category-admin-card">
                      <div className="cat-admin-img-wrap">
                        <img
                          src={cat.image || 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=400&q=80'}
                          alt={cat.name}
                        />
                      </div>
                      <div className="cat-admin-body">
                        <h3 className="cat-admin-name">{cat.name}</h3>
                        <p className="cat-admin-slug">/{cat.slug}</p>
                        <div className="cat-admin-actions">
                          <button
                            className="table-action-btn edit"
                            onClick={() => handleOpenCategoryModal(cat)}
                          >
                            ✏️ Edit
                          </button>
                          <button
                            className="table-action-btn delete"
                            onClick={() => handleDeleteCategory(cat.id)}
                          >
                            🗑️ Delete
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}

                  {shopCategories.length === 0 && (
                    <div className="empty-state-msg">
                      No categories yet. Click "+ Add Category" to create your first one.
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* 5. BANNERS TAB */}
            {activeTab === 'banners' && (
              <div className="admin-tab-content">
                <header className="admin-header">
                  <div>
                    <h1 className="admin-page-title">Hero Section Banners</h1>
                    <p className="admin-subtitle">Add or remove promotional hero section banners</p>
                  </div>
                  <button className="btn btn-primary" onClick={() => setBannerModalOpen(true)}>
                    + Add Banner
                  </button>
                </header>

                <div className="banners-grid">
                  {banners.map(banner => (
                    <div key={banner.id} className="banner-card">
                      <div className="banner-img-wrap">
                        <img src={banner.image} alt={banner.title} />
                      </div>
                      <div className="banner-body">
                        <h3>{banner.title}</h3>
                        <p>{banner.subtitle}</p>
                        <span className="banner-link-tag">Link: {banner.link}</span>
                        <button className="btn btn-outline danger btn-sm" onClick={() => handleDeleteBanner(banner.id)}>
                          Delete Banner
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </>
        )}
      </main>

      {/* --- ADD / EDIT PRODUCT MODAL --- */}
      {productModalOpen && (
        <div className="modal-overlay">
          <div className="modal-dialog">
            <div className="modal-header">
              <h2>{editingProduct ? 'Edit Product' : 'Add New Product'}</h2>
              <button className="modal-close" onClick={() => setProductModalOpen(false)}>×</button>
            </div>
            <form onSubmit={handleSaveProduct} className="modal-form">
              <div className="form-group">
                <label>Product Images</label>
                <div className="file-upload-box">
                  <input
                    type="file"
                    accept="image/*"
                    id="product-file-input"
                    className="file-input-hidden"
                    onChange={(e) => {
                      const file = e.target.files[0];
                      if (file) {
                        const reader = new FileReader();
                        reader.onloadend = () => {
                          setProductForm({ ...productForm, image: reader.result });
                        };
                        reader.readAsDataURL(file);
                      }
                    }}
                  />
                  <label htmlFor="product-file-input" className="file-upload-label">
                    {productForm.image ? (
                      <div className="uploaded-preview">
                        <img src={productForm.image} alt="Preview" />
                        <span>Change Image</span>
                      </div>
                    ) : (
                      <div className="upload-placeholder">
                        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                          <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M17 8l-5-5-5 5M12 3v12" />
                        </svg>
                        <span>Add Image from Device</span>
                      </div>
                    )}
                  </label>
                </div>
              </div>

              <div className="form-group">
                <label>Product Name</label>
                <input
                  type="text"
                  placeholder="Enter product name"
                  value={productForm.name}
                  onChange={e => setProductForm({ ...productForm, name: e.target.value })}
                  required
                />
              </div>

              <div className="form-group">
                <label>Slug</label>
                <input
                  type="text"
                  placeholder="product-slug"
                  value={productForm.slug}
                  onChange={e => setProductForm({ ...productForm, slug: e.target.value })}
                />
              </div>

              <div className="form-group">
                <label>Description</label>
                <textarea
                  placeholder="Product description"
                  value={productForm.description}
                  onChange={e => setProductForm({ ...productForm, description: e.target.value })}
                  rows={3}
                />
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Price (₹)</label>
                  <input
                    type="number"
                    placeholder="0.00"
                    value={productForm.price}
                    onChange={e => setProductForm({ ...productForm, price: e.target.value })}
                    required
                  />
                </div>
                <div className="form-group">
                  <label>Discount Price (Optional)</label>
                  <input
                    type="number"
                    placeholder="0.00"
                    value={productForm.originalPrice}
                    onChange={e => setProductForm({ ...productForm, originalPrice: e.target.value })}
                  />
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Stock</label>
                  <input
                    type="number"
                    value={productForm.stock}
                    onChange={e => setProductForm({ ...productForm, stock: e.target.value })}
                    required
                  />
                </div>
                <div className="form-group">
                  <label>Category</label>
                  <select
                    value={productForm.categories[0]}
                    onChange={e => setProductForm({ ...productForm, categories: [e.target.value] })}
                  >
                    {shopCategories.map((cat) => (
                      <option key={cat.id || cat.slug} value={cat.slug}>
                        {cat.name}
                      </option>
                    ))}
                    {/* Fallback to default categories if database categories didn't load */}
                    {shopCategories.length === 0 && (
                      <>
                        <option value="necklaces">Necklaces</option>
                        <option value="earrings">Earrings</option>
                        <option value="pendant-sets">Pendant Sets</option>
                        <option value="bangles-bracelets">Bangles &amp; Bracelets</option>
                        <option value="rings">Rings</option>
                        <option value="maangtika">Maangtika</option>
                        <option value="hathpans">Hathpans</option>
                        <option value="gold-plated-necklace">Gold-Plated Necklaces</option>
                        <option value="silver-earrings">Silver Earrings</option>
                        <option value="anti-tarnish">Anti-Tarnish</option>
                      </>
                    )}
                  </select>
                </div>
              </div>

              <div className="form-checkbox-group">
                <label>
                  <input
                    type="checkbox"
                    checked={productForm.isBestseller}
                    onChange={e => setProductForm({ ...productForm, isBestseller: e.target.checked })}
                  />
                  Mark as Bestseller
                </label>
                <label>
                  <input
                    type="checkbox"
                    checked={productForm.isFeatured}
                    onChange={e => setProductForm({ ...productForm, isFeatured: e.target.checked })}
                  />
                  Mark as Featured
                </label>
              </div>

              <div className="modal-actions">
                <button type="button" className="btn btn-outline" onClick={() => setProductModalOpen(false)}>Cancel</button>
                <button type="submit" className="btn btn-primary">{editingProduct ? 'Update Product' : 'Add Product'}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* --- ORDER DETAILS MODAL --- */}
      {selectedOrder && (
        <div className="modal-overlay">
          <div className="modal-dialog">
            <div className="modal-header">
              <h2>Order Details {selectedOrder.id}</h2>
              <button className="modal-close" onClick={() => setSelectedOrder(null)}>×</button>
            </div>
            <div className="order-details-body">
              <div className="order-details-grid">
                <div className="details-card">
                  <h4>🎁 Customer Info</h4>
                  <p><strong>Name:</strong> {selectedOrder.customer.name}</p>
                  <p><strong>Email:</strong> {selectedOrder.customer.email}</p>
                  <p><strong>Phone:</strong> {selectedOrder.customer.phone}</p>
                </div>

                <div className="details-card">
                  <h4>🚚 Shipping Address</h4>
                  <p>{selectedOrder.address}</p>
                </div>
              </div>

              <h4 className="section-subtitle-modal">Order Items</h4>
              <table className="admin-table">
                <thead>
                  <tr>
                    <th>Product</th>
                    <th>Price</th>
                    <th>Qty</th>
                    <th>Total</th>
                  </tr>
                </thead>
                <tbody>
                  {selectedOrder.items.map((item, idx) => (
                    <tr key={idx}>
                      <td>{item.name}</td>
                      <td>₹{item.price.toFixed(2)}</td>
                      <td>{item.qty}</td>
                      <td>₹{(item.price * item.qty).toFixed(2)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>

              <div className="order-summary-box">
                <p><strong>Payment Method:</strong> {selectedOrder.paymentMethod}</p>
                <p><strong>Payment Status:</strong> <span className="status-completed">{selectedOrder.paymentStatus}</span></p>
                <div className="order-status-row">
                  <strong>Order Status:</strong>
                  <select
                    value={selectedOrder.orderStatus}
                    onChange={(e) => handleUpdateOrderStatus(selectedOrder.id, e.target.value)}
                    className="order-select-status"
                  >
                    <option value="Pending">Pending</option>
                    <option value="Processing">Processing</option>
                    <option value="Shipped">Shipped</option>
                    <option value="Delivered">Delivered</option>
                    <option value="Cancelled">Cancelled</option>
                  </select>
                </div>
                <h3 className="total-price-tag">Total Amount: ₹{selectedOrder.totalAmount.toFixed(2)}</h3>
              </div>
            </div>
            <div className="modal-actions">
              <button className="btn btn-primary" onClick={() => setSelectedOrder(null)}>Close</button>
            </div>
          </div>
        </div>
      )}

      {/* --- ADD BANNER MODAL --- */}
      {bannerModalOpen && (
        <div className="modal-overlay">
          <div className="modal-dialog">
            <div className="modal-header">
              <h2>Add Hero Section Banner</h2>
              <button className="modal-close" onClick={() => setBannerModalOpen(false)}>×</button>
            </div>
            <form onSubmit={handleCreateBanner} className="modal-form">
              <div className="form-group">
                <label>Banner Image</label>
                <div style={{ fontSize: '0.8rem', color: '#666', marginBottom: '0.5rem' }}>
                  💡 <strong>Recommended sizes for a perfect fit:</strong><br />
                  • Desktop: <strong>1600 × 640 px</strong> or <strong>1920 × 768 px</strong> (Aspect ratio 5:2)<br />
                  • Mobile: <strong>800 × 800 px</strong> (Square 1:1)
                </div>
                <div className="file-upload-box">
                  <input
                    type="file"
                    accept="image/*"
                    id="banner-file-input"
                    className="file-input-hidden"
                    onChange={(e) => {
                      const file = e.target.files[0];
                      if (file) {
                        const reader = new FileReader();
                        reader.onloadend = () => {
                          setBannerForm({ ...bannerForm, image: reader.result });
                        };
                        reader.readAsDataURL(file);
                      }
                    }}
                  />
                  <label htmlFor="banner-file-input" className="file-upload-label">
                    {bannerForm.image ? (
                      <div className="uploaded-preview banner">
                        <img src={bannerForm.image} alt="Banner Preview" />
                        <span>Change Image</span>
                      </div>
                    ) : (
                      <div className="upload-placeholder">
                        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                          <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M17 8l-5-5-5 5M12 3v12" />
                        </svg>
                        <span>Add Image from Device</span>
                      </div>
                    )}
                  </label>
                </div>
              </div>

              <div className="form-group">
                <label>Banner Title</label>
                <input
                  type="text"
                  placeholder="e.g. Royal Bridal Collection"
                  value={bannerForm.title}
                  onChange={e => setBannerForm({ ...bannerForm, title: e.target.value })}
                  required
                />
              </div>

              <div className="form-group">
                <label>Subtitle / Description</label>
                <input
                  type="text"
                  placeholder="e.g. Handcrafted 92.5 pure silver sets"
                  value={bannerForm.subtitle}
                  onChange={e => setBannerForm({ ...bannerForm, subtitle: e.target.value })}
                />
              </div>

              <div className="form-group">
                <label>Target Link</label>
                <input
                  type="text"
                  placeholder="/collections"
                  value={bannerForm.link}
                  onChange={e => setBannerForm({ ...bannerForm, link: e.target.value })}
                />
              </div>

              <div className="modal-actions">
                <button type="button" className="btn btn-outline" onClick={() => setBannerModalOpen(false)}>Cancel</button>
                <button type="submit" className="btn btn-primary">Add Banner</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* --- ADD / EDIT CATEGORY MODAL --- */}
      {categoryModalOpen && (
        <div className="modal-overlay">
          <div className="modal-dialog">
            <div className="modal-header">
              <h2>{editingCategory ? 'Edit Category' : 'Add New Category'}</h2>
              <button className="modal-close" onClick={() => setCategoryModalOpen(false)}>×</button>
            </div>
            <form onSubmit={handleSaveCategory} className="modal-form">

              {/* Image Upload */}
              <div className="form-group">
                <label>Category Image</label>
                <div className="file-upload-box">
                  <input
                    type="file"
                    accept="image/*"
                    id="category-file-input"
                    className="file-input-hidden"
                    onChange={(e) => {
                      const file = e.target.files[0];
                      if (file) {
                        const reader = new FileReader();
                        reader.onloadend = () => {
                          setCategoryForm({ ...categoryForm, image: reader.result });
                        };
                        reader.readAsDataURL(file);
                      }
                    }}
                  />
                  <label htmlFor="category-file-input" className="file-upload-label">
                    {categoryForm.image ? (
                      <div className="uploaded-preview">
                        <img src={categoryForm.image} alt="Preview" />
                        <span>Change Image</span>
                      </div>
                    ) : (
                      <div className="upload-placeholder">
                        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                          <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M17 8l-5-5-5 5M12 3v12" />
                        </svg>
                        <span>Upload Image from Device</span>
                      </div>
                    )}
                  </label>
                </div>
                {/* OR paste image URL */}
                <input
                  type="url"
                  placeholder="Or paste an image URL (https://...)"
                  value={categoryForm.image && !categoryForm.image.startsWith('data:') ? categoryForm.image : ''}
                  onChange={e => setCategoryForm({ ...categoryForm, image: e.target.value })}
                  style={{ marginTop: '0.5rem' }}
                />
              </div>

              {/* Category Name */}
              <div className="form-group">
                <label>Category Name</label>
                <input
                  type="text"
                  placeholder="e.g. Necklaces"
                  value={categoryForm.name}
                  onChange={e => {
                    const name = e.target.value;
                    const autoSlug = name.toLowerCase().trim().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
                    setCategoryForm({ ...categoryForm, name, slug: autoSlug });
                  }}
                  required
                />
              </div>

              {/* Slug */}
              <div className="form-group">
                <label>Slug (URL key — auto-generated)</label>
                <input
                  type="text"
                  placeholder="e.g. necklaces"
                  value={categoryForm.slug}
                  onChange={e => setCategoryForm({ ...categoryForm, slug: e.target.value })}
                />
                <small style={{ color: 'var(--color-text-muted)', fontSize: '0.75rem' }}>
                  This links to: <code>/collections?category={categoryForm.slug || 'slug'}</code>
                </small>
              </div>

              <div className="modal-actions">
                <button type="button" className="btn btn-outline" onClick={() => setCategoryModalOpen(false)}>Cancel</button>
                <button type="submit" className="btn btn-primary">
                  {editingCategory ? 'Update Category' : 'Add Category'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>

  );
};

export default Admin;
