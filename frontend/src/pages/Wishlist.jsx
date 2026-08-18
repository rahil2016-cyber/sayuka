import React from 'react';
import { Link } from 'react-router-dom';
import { useWishlist } from '../context/WishlistContext';
import { useCart } from '../context/CartContext';
import './Wishlist.css';

const Wishlist = () => {
  const { wishlistItems, removeFromWishlist } = useWishlist();
  const { addToCart } = useCart();

  const handleAddToCart = (product) => {
    addToCart(product);
    // Optional: remove from wishlist after adding to cart
    removeFromWishlist(product.id);
  };

  const formatPrice = (price) =>
    `₹${Number(price).toLocaleString('en-IN')}`;

  return (
    <div className="wishlist-page page-content">
      <div className="container">
        {/* Header Section */}
        <div className="wishlist-header text-center">
          <p className="wishlist-subtitle">YOUR FAVORITE PIECES</p>
          <h1 className="wishlist-title">My Wishlist</h1>
          <div className="wishlist-divider">
            <span className="divider-line"></span>
            <span className="diamond-motif">✦</span>
            <span className="divider-line"></span>
          </div>
        </div>

        {wishlistItems.length === 0 ? (
          <div className="wishlist-empty text-center">
            <div className="empty-icon">❤️</div>
            <h2>Your wishlist is empty</h2>
            <p>Save items you like here to keep track of them!</p>
            <Link to="/collections" className="btn btn-primary">
              Continue Shopping
            </Link>
          </div>
        ) : (
          <div className="wishlist-grid">
            {wishlistItems.map((product) => {
              const imageUrl = Array.isArray(product.images) && product.images.length > 0
                ? product.images[0]
                : product.image || 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80';

              return (
                <div key={product.id} className="wishlist-item-card">
                  <button
                    className="remove-wishlist-btn"
                    onClick={() => removeFromWishlist(product.id)}
                    aria-label="Remove from wishlist"
                  >
                    ×
                  </button>
                  <Link to={`/product/${product.id}`} className="wishlist-item-link">
                    <div className="wishlist-img-wrap">
                      <img src={imageUrl} alt={product.name} />
                    </div>
                    <div className="wishlist-item-info">
                      <h3 className="wishlist-item-name">{product.name}</h3>
                      <div className="wishlist-item-price">{formatPrice(product.price)}</div>
                    </div>
                  </Link>
                  <div className="wishlist-item-actions">
                    <button
                      className="btn btn-primary btn-sm add-to-cart-wish"
                      onClick={() => handleAddToCart(product)}
                      disabled={product.inStock === false}
                    >
                      {product.inStock === false ? 'Out of Stock' : 'Add to Cart'}
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};

export default Wishlist;
