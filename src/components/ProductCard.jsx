import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { useCart } from '../context/CartContext';
import './ProductCard.css';

const ProductCard = ({ product }) => {
  const { addToCart } = useCart();
  const [wishlist, setWishlist] = useState(false);
  const [addedToCart, setAddedToCart] = useState(false);

  const handleAddToCart = (e) => {
    e.preventDefault();
    e.stopPropagation();
    addToCart(product);
    setAddedToCart(true);
    setTimeout(() => setAddedToCart(false), 1500);
  };

  const handleWishlist = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setWishlist(!wishlist);
  };

  const formatPrice = (price) =>
    `₹${Number(price).toLocaleString('en-IN')}`;

  const imageUrl = Array.isArray(product.images) && product.images.length > 0
    ? product.images[0]
    : product.image || 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80';

  return (
    <div className="product-card-luxury">
      <Link to={`/product/${product.id}`} className="product-card-link">
        <div className="product-card-img-container">
          <img
            src={imageUrl}
            alt={product.name}
            className="product-card-img"
            loading="lazy"
          />
          
          {/* Top Left Bestseller / Badge Tag */}
          {product.badge && (
            <span className="product-card-badge">
              {product.badge}
            </span>
          )}

          {/* Top Right Wishlist Button */}
          <button
            className={`product-card-wishlist ${wishlist ? 'active' : ''}`}
            onClick={handleWishlist}
            aria-label="Add to wishlist"
            id={`wishlist-${product.id}`}
          >
            <svg width="15" height="15" viewBox="0 0 24 24" fill={wishlist ? "#E91E63" : "none"} stroke={wishlist ? "#E91E63" : "#3D3D3D"} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
              <path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z"/>
            </svg>
          </button>
        </div>

        {/* Card Body Footer */}
        <div className="product-card-body">
          <div className="product-card-text">
            <h3 className="product-card-title">{product.name}</h3>
            <div className="product-card-price">{formatPrice(product.price)}</div>
          </div>

          {/* Shopping Bag Button */}
          <button
            className={`product-card-bag-btn ${addedToCart ? 'added' : ''}`}
            onClick={handleAddToCart}
            title="Add to Cart"
            id={`add-to-cart-${product.id}`}
          >
            {addedToCart ? (
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#2D122D" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <polyline points="20 6 9 17 4 12"></polyline>
              </svg>
            ) : (
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#3B1A3B" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                <path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"></path>
                <line x1="3" y1="6" x2="21" y2="6"></line>
                <path d="M16 10a4 4 0 0 1-8 0"></path>
              </svg>
            )}
          </button>
        </div>
      </Link>
    </div>
  );
};

export default ProductCard;
