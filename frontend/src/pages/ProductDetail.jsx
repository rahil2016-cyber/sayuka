import React, { useState, useEffect } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import { productsAPI } from '../api';
import { useCart } from '../context/CartContext';
import './ProductDetail.css';

const ProductDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { addToCart } = useCart();
  const [product, setProduct] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeImage, setActiveImage] = useState(0);
  const [quantity, setQuantity] = useState(1);
  const [added, setAdded] = useState(false);

  useEffect(() => {
    const fetchProduct = async () => {
      try {
        const res = await productsAPI.getById(id);
        setProduct(res.data.data);
      } catch {
        navigate('/collections');
      } finally {
        setLoading(false);
      }
    };
    fetchProduct();
    window.scrollTo(0, 0);
  }, [id, navigate]);

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

  if (!product) return null;

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
              {product.images.map((img, i) => (
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
                src={product.images[activeImage]}
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
            <div className="quantity-section">
              <label className="quantity-label">Quantity</label>
              <div className="quantity-control">
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

            {/* Actions */}
            <div className="product-actions">
              <button
                className={`btn btn-primary btn-lg add-to-cart-btn ${added ? 'added' : ''}`}
                onClick={handleAddToCart}
                disabled={!product.inStock}
                id="add-to-cart-detail"
              >
                {!product.inStock ? 'Out of Stock' : added ? '✓ Added to Cart!' : 'Add to Cart'}
              </button>
              {product.inStock && (
                <button
                  className="btn btn-outline btn-lg"
                  onClick={handleBuyNow}
                  id="buy-now-btn"
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
