import React, { useState, useEffect } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import { productsAPI } from '../api';
import { useCart } from '../context/CartContext';
import { useWishlist } from '../context/WishlistContext';
import './ProductDetail.css';

const ProductDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { addToCart } = useCart();
  const { toggleWishlist, isInWishlist } = useWishlist();
  const [product, setProduct] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [activeImage, setActiveImage] = useState(0);
  const [quantity, setQuantity] = useState(1);
  const [added, setAdded] = useState(false);

  useEffect(() => {
    const fetchProduct = async () => {
      setLoading(true);
      setError(null);
      try {
        const res = await productsAPI.getById(id);
        setProduct(res.data.data);
      } catch (err) {
        setError('Product not found or server is unavailable. Please try again.');
      } finally {
        setLoading(false);
      }
    };
    fetchProduct();
    window.scrollTo(0, 0);
  }, [id]);

  const handleAddToCart = () => {
    for (let i = 0; i < quantity; i++) {
      addToCart(product);
    }
    setAdded(true);
    setTimeout(() => setAdded(false), 2000);
  };

  const handleBuyNow = () => {
    addToCart(product);
    navigate('/cart');
  };

  if (loading) {
    return <div className="page-content loading-container"><div className="spinner" /></div>;
  }

  if (error || !product) {
    return (
      <div className="page-content" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '60vh', textAlign: 'center', gap: '1.5rem' }}>
        <div style={{ fontSize: '4rem' }}>💎</div>
        <h2 style={{ fontFamily: 'var(--font-heading)', color: 'var(--color-deep-purple)' }}>Product Not Found</h2>
        <p style={{ color: 'var(--color-text-muted)' }}>{error || 'This product does not exist.'}</p>
        <div style={{ display: 'flex', gap: '1rem' }}>
          <button onClick={() => navigate(-1)} className="btn btn-outline">← Go Back</button>
          <Link to="/collections" className="btn btn-primary">Browse Collections</Link>
        </div>
      </div>
    );
  }

  // Guard: ensure images is always an array
  const images = Array.isArray(product.images) && product.images.length > 0
    ? product.images
    : product.image
      ? [product.image]
      : ['https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80'];

  return (
    <div className="product-detail-page page-content">
      <div className="container">
        {/* Breadcrumb */}
        <nav className="breadcrumb">
          <Link to="/">Home</Link>
          <span>›</span>
          <Link to="/collections">Collections</Link>
          <span>›</span>
          <Link to={`/collections?category=${product.category}`} style={{ textTransform: 'capitalize' }}>
            {product.category}
          </Link>
          <span>›</span>
          <span>{product.name}</span>
        </nav>

        {/* Product Layout */}
        <div className="product-detail-layout">
          {/* Left: Images */}
          <div className="product-images">
            <div className="product-thumbnails">
              {images.map((img, i) => (
                <button
                  key={i}
                  className={`thumbnail-btn ${activeImage === i ? 'active' : ''}`}
                  onClick={() => setActiveImage(i)}
                  id={`thumbnail-${i}`}
                >
                  <img src={img} alt={`${product.name} view ${i + 1}`} />
                </button>
              ))}
            </div>
            <div className="product-main-image-wrap">
              <img
                src={images[activeImage]}
                alt={product.name}
                className="product-main-image"
              />
              {product.badge && (
                <span className={`product-badge badge-${product.badge.toLowerCase()}`}>
                  {product.badge}
                </span>
              )}
            </div>
          </div>

          {/* Right: Info */}
          <div className="product-info-panel">
            <div className="product-category-label">{product.category}</div>
            <h1 className="detail-product-name">{product.name}</h1>
            <div className="detail-price">
              <span className="detail-price-current">₹ {product.price.toLocaleString('en-IN')}</span>
              {product.originalPrice > product.price && (
                <>
                  <span className="detail-price-original">₹ {product.originalPrice.toLocaleString('en-IN')}</span>
                  <span className="detail-discount">
                    {Math.round(((product.originalPrice - product.price) / product.originalPrice) * 100)}% off
                  </span>
                </>
              )}
            </div>

            <p className="detail-description">{product.description}</p>

            {/* Specs */}
            <div className="product-specs">
              {product.gemstone && (
                <div className="spec-row">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polygon points="6 3 18 3 22 9 12 22 2 9"/></svg>
                  <span><strong>Gemstone:</strong> {product.gemstone}</span>
                </div>
              )}
              <div className="spec-row">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="20 6 9 17 4 12"/></svg>
                <span><strong>100% Certified & Hallmarked Jewellery</strong></span>
              </div>
            </div>

            {/* Quantity */}
            <div className="quantity-section" style={{ display: 'flex', alignItems: 'center', gap: '1.2rem' }}>
              <div>
                <label className="quantity-label">Quantity</label>
                <div className="quantity-control" style={{ marginBottom: 0 }}>
                  <button
                    onClick={() => setQuantity(q => Math.max(1, q - 1))}
                    className="qty-btn"
                    id="qty-decrease"
                  >−</button>
                  <span className="qty-value">{quantity}</span>
                  <button
                    onClick={() => setQuantity(q => q + 1)}
                    className="qty-btn"
                    id="qty-increase"
                  >+</button>
                </div>
              </div>

              {/* Wishlist Button beside quantity */}
              <div style={{ marginTop: '1.8rem' }}>
                <button
                  className={`wishlist-btn-detail ${isInWishlist(product.id) ? 'active' : ''}`}
                  onClick={() => toggleWishlist(product)}
                  title="Add to Wishlist"
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    width: '46px',
                    height: '46px',
                    borderRadius: '50%',
                    border: '1px solid rgba(97, 58, 104, 0.25)',
                    background: isInWishlist(product.id) ? 'rgba(233, 30, 99, 0.1)' : '#fff',
                    cursor: 'pointer',
                    transition: 'all 0.3s ease'
                  }}
                >
                  <svg width="22" height="22" viewBox="0 0 24 24" fill={isInWishlist(product.id) ? "#E91E63" : "none"} stroke={isInWishlist(product.id) ? "#E91E63" : "#3D3D3D"} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z"/>
                  </svg>
                </button>
              </div>
            </div>

            {/* Actions */}
            <div className="product-actions" style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
              <button
                className={`btn btn-primary btn-lg add-to-cart-btn ${added ? 'added' : ''}`}
                onClick={handleAddToCart}
                disabled={!product.inStock}
                id="add-to-cart-detail"
                style={{ flex: 1 }}
              >
                {!product.inStock ? 'Out of Stock' : added ? '✓ Added to Cart!' : 'Add to Cart'}
              </button>
              {product.inStock && (
                <button
                  className="btn btn-outline btn-lg"
                  onClick={handleBuyNow}
                  id="buy-now-btn"
                  style={{ flex: 1 }}
                >
                  Buy Now
                </button>
              )}
            </div>

            {/* Trust badges */}
            <div className="trust-badges">
              <div className="trust-badge">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                <span>Certified Jewellery</span>
              </div>
              <div className="trust-badge">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><rect x="1" y="3" width="15" height="13"/><polygon points="16 8 20 8 23 11 23 16 16 16 16 8"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/></svg>
                <span>Easy Returns</span>
              </div>
              <div className="trust-badge">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
                <span>Secure Payment</span>
              </div>
              <div className="trust-badge">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M14 9V5a3 3 0 00-3-3l-4 9v11h11.28a2 2 0 002-1.7l1.38-9a2 2 0 00-2-2.3z"/><path d="M7 22H4a2 2 0 01-2-2v-7a2 2 0 012-2h3"/></svg>
                <span>Free Shipping</span>
              </div>
            </div>
          </div>
        </div>

        {/* Trust Badges section ends here */}
      </div>
    </div>
  );
};

export default ProductDetail;
