import React from 'react';
import { Link } from 'react-router-dom';
import { useCart } from '../context/CartContext';
import './Cart.css';

const Cart = () => {
  const { items, totalItems, totalPrice, removeFromCart, updateQuantity, clearCart } = useCart();

  const formatPrice = (price) => `₹ ${price.toLocaleString('en-IN')}`;
  const shipping = totalPrice > 0 && totalPrice < 1999 ? 99 : 0;
  const grandTotal = totalPrice + shipping;

  if (items.length === 0) {
    return (
      <div className="cart-page page-content">
        <div className="container">
          <div className="empty-cart">
            <div className="empty-cart-icon">
              <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1"><path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z"/><line x1="3" y1="6" x2="21" y2="6"/><path d="M16 10a4 4 0 01-8 0"/></svg>
            </div>
            <h2>Your cart is empty</h2>
            <p>Looks like you haven't added any jewellery yet.</p>
            <Link to="/collections" className="btn btn-primary btn-lg">Explore Collections</Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="cart-page page-content">
      <div className="container">
        <div className="cart-header">
          <h1 className="cart-title">Your Cart ({totalItems} items)</h1>
          <Link to="/collections" className="continue-shopping">← Continue Shopping</Link>
        </div>

        <div className="cart-layout">
          {/* Items */}
          <div className="cart-items">
            {items.map(item => (
              <div key={item.id} className="cart-item">
                <div className="cart-item-image">
                  <img src={item.images[0]} alt={item.name} />
                </div>
                <div className="cart-item-info">
                  <Link to={`/product/${item.id}`} className="cart-item-name">{item.name}</Link>
                  <div className="cart-item-meta">
                    <span style={{ textTransform: 'capitalize' }}>{item.category}</span>
                    {item.material && <span>• {item.material}</span>}
                  </div>
                  <div className="cart-item-price">{formatPrice(item.price)}</div>
                </div>
                <div className="cart-item-actions">
                  <div className="cart-qty">
                    <button
                      onClick={() => updateQuantity(item.id, item.quantity - 1)}
                      className="qty-btn"
                      disabled={item.quantity <= 1}
                    >−</button>
                    <span>{item.quantity}</span>
                    <button
                      onClick={() => updateQuantity(item.id, item.quantity + 1)}
                      className="qty-btn"
                    >+</button>
                  </div>
                  <div className="cart-item-total">{formatPrice(item.price * item.quantity)}</div>
                  <button
                    className="remove-btn"
                    onClick={() => removeFromCart(item.id)}
                    aria-label={`Remove ${item.name}`}
                    id={`remove-${item.id}`}
                  >
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a1 1 0 011-1h4a1 1 0 011 1v2"/></svg>
                  </button>
                </div>
              </div>
            ))}

            <button className="clear-cart-btn" onClick={clearCart} id="clear-cart">
              Clear All Items
            </button>
          </div>

          {/* Summary */}
          <div className="cart-summary">
            <h3 className="summary-title">Order Summary</h3>
            <div className="summary-rows">
              <div className="summary-row">
                <span>Subtotal ({totalItems} items)</span>
                <span>{formatPrice(totalPrice)}</span>
              </div>
              <div className="summary-row">
                <span>Shipping</span>
                <span>{shipping === 0 ? <span className="free-shipping">FREE</span> : formatPrice(shipping)}</span>
              </div>
              {shipping > 0 && (
                <div className="shipping-note">
                  Add {formatPrice(1999 - totalPrice)} more for free shipping
                </div>
              )}
            </div>
            <div className="summary-total">
              <span>Total</span>
              <span>{formatPrice(grandTotal)}</span>
            </div>
            <Link to="/checkout" className="btn btn-primary btn-lg checkout-btn text-center" id="checkout-btn" style={{ display: 'block', textDecoration: 'none' }}>
              Proceed to Checkout
            </Link>
            <div className="payment-methods">
              <span>Secure Payment via</span>
              <div className="payment-icons">
                <span className="payment-badge">Razorpay</span>
                <span className="payment-badge">UPI</span>
                <span className="payment-badge">Cards</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Cart;
