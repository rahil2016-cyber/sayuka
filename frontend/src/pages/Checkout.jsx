import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useCart } from '../context/CartContext';
import { adminAPI } from '../api';
import './Checkout.css';

const Checkout = () => {
  const { items, totalPrice, clearCart } = useCart();
  const navigate = useNavigate();

  // Form states
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    whatsapp: '',
    address: '',
    city: '',
    state: '',
    pincode: '',
  });

  const [deliveryOption, setDeliveryOption] = useState('home'); // 'home' or 'store'
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [orderSuccess, setOrderSuccess] = useState(null);

  const formatPrice = (price) => `₹ ${price.toLocaleString('en-IN')}`;

  const deliveryCharge = deliveryOption === 'home' ? 120 : 0;
  const grandTotal = totalPrice + deliveryCharge;

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (items.length === 0) return;

    setIsSubmitting(true);
    try {
      const orderPayload = {
        customer: {
          name: formData.name,
          email: formData.email,
          phone: formData.whatsapp, // Save WhatsApp number as the phone field
        },
        address:
          deliveryOption === 'home'
            ? `${formData.address}, ${formData.city}, ${formData.state} - ${formData.pincode}`
            : 'Store Pickup (Davangere Showroom)',
        items: items.map((item) => ({
          name: item.name,
          price: item.price,
          qty: item.quantity,
        })),
        totalAmount: grandTotal,
        paymentMethod: 'Online Payment',
      };

      const res = await adminAPI.createOrder(orderPayload);
      if (res.data.success) {
        setOrderSuccess(res.data.data);
        clearCart();
      }
    } catch (err) {
      alert('Order placement failed: ' + (err.response?.data?.message || err.message));
    } finally {
      setIsSubmitting(false);
    }
  };

  if (orderSuccess) {
    return (
      <div className="checkout-page page-content text-center">
        <div className="container success-container">
          <div className="success-icon">🎉</div>
          <h1 className="success-title">Order Placed Successfully!</h1>
          <p className="success-order-id">Order ID: <strong>{orderSuccess.id}</strong></p>
          <div className="success-card">
            <h3>Thank you, {orderSuccess.customer.name}!</h3>
            <p>Your order details have been received. We will connect with you on WhatsApp (<strong>{orderSuccess.customer.phone}</strong>) shortly.</p>
            <div className="success-amount">Total paid: {formatPrice(orderSuccess.totalAmount)}</div>
          </div>
          <Link to="/collections" className="btn btn-primary btn-lg mt-4">
            Continue Shopping
          </Link>
        </div>
      </div>
    );
  }

  if (items.length === 0) {
    return (
      <div className="checkout-page page-content text-center">
        <div className="container">
          <h2>No items in cart</h2>
          <p>Please add products before checking out.</p>
          <Link to="/collections" className="btn btn-primary">
            Browse Collections
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="checkout-page page-content">
      <div className="container">
        <h1 className="checkout-main-title">Checkout</h1>
        <div className="checkout-layout">
          {/* Form */}
          <form onSubmit={handleSubmit} className="checkout-form-panel">
            {/* Customer Details */}
            <div className="checkout-section">
              <h2 className="section-title">
                <span className="section-icon">👤</span> Customer Details
              </h2>
              <div className="form-grid-2">
                <div className="form-group">
                  <label htmlFor="name">Full Name</label>
                  <input
                    type="text"
                    id="name"
                    name="name"
                    value={formData.name}
                    onChange={handleChange}
                    placeholder="Enter your name"
                    required
                  />
                </div>
                <div className="form-group">
                  <label htmlFor="email">Email</label>
                  <input
                    type="email"
                    id="email"
                    name="email"
                    value={formData.email}
                    onChange={handleChange}
                    placeholder="Enter email address"
                    required
                  />
                </div>
              </div>
              <div className="form-group">
                <label htmlFor="whatsapp">WhatsApp Number</label>
                <input
                  type="tel"
                  id="whatsapp"
                  name="whatsapp"
                  value={formData.whatsapp}
                  onChange={handleChange}
                  placeholder="Enter 10-digit WhatsApp number"
                  required
                />
              </div>
            </div>

            {/* Delivery Option */}
            <div className="checkout-section">
              <h2 className="section-title">
                <span className="section-icon">📦</span> Delivery Option
              </h2>
              <div className="delivery-options-grid">
                <button
                  type="button"
                  className={`delivery-option-btn ${deliveryOption === 'home' ? 'active' : ''}`}
                  onClick={() => setDeliveryOption('home')}
                >
                  <div className="radio-circle"></div>
                  <div className="delivery-btn-text">
                    <strong>Home Delivery</strong>
                    <span>+₹120 delivery charge</span>
                  </div>
                </button>
                <button
                  type="button"
                  className={`delivery-option-btn ${deliveryOption === 'store' ? 'active' : ''}`}
                  onClick={() => setDeliveryOption('store')}
                >
                  <div className="radio-circle"></div>
                  <div className="delivery-btn-text">
                    <strong>Store Pickup</strong>
                    <span>Free (No delivery charge)</span>
                  </div>
                </button>
              </div>
            </div>

            {/* Delivery Address */}
            {deliveryOption === 'home' && (
              <div className="checkout-section">
                <h2 className="section-title">
                  <span className="section-icon">📍</span> Delivery Address
                </h2>
                <div className="form-group">
                  <label htmlFor="address">Full Address</label>
                  <input
                    type="text"
                    id="address"
                    name="address"
                    value={formData.address}
                    onChange={handleChange}
                    placeholder="House No, Building Name, Street..."
                    required
                  />
                </div>
                <div className="form-grid-3">
                  <div className="form-group">
                    <label htmlFor="city">City</label>
                    <input
                      type="text"
                      id="city"
                      name="city"
                      value={formData.city}
                      onChange={handleChange}
                      placeholder="City"
                      required
                    />
                  </div>
                  <div className="form-group">
                    <label htmlFor="state">State</label>
                    <input
                      type="text"
                      id="state"
                      name="state"
                      value={formData.state}
                      onChange={handleChange}
                      placeholder="State"
                      required
                    />
                  </div>
                  <div className="form-group">
                    <label htmlFor="pincode">Pincode</label>
                    <input
                      type="text"
                      id="pincode"
                      name="pincode"
                      value={formData.pincode}
                      onChange={handleChange}
                      placeholder="Pincode"
                      required
                    />
                  </div>
                </div>
              </div>
            )}

            {/* Payment Method */}
            <div className="checkout-section">
              <h2 className="section-title">
                <span className="section-icon">💳</span> Payment Method
              </h2>
              <div className="payment-option-card">
                <div className="radio-circle active"></div>
                <div className="payment-option-text">
                  <strong>Pay Online (Cards/UPI/NetBanking)</strong>
                </div>
              </div>
            </div>

            <button
              type="submit"
              className="btn btn-primary btn-lg place-order-btn"
              disabled={isSubmitting}
            >
              {isSubmitting ? 'Placing Order...' : `Place Order - ${formatPrice(grandTotal)}`}
            </button>
          </form>

          {/* Sidebar Summary */}
          <div className="checkout-sidebar-summary">
            <h2 className="summary-title">Order Summary</h2>
            <div className="summary-products-list">
              {items.map((item) => {
                const img = Array.isArray(item.images) && item.images.length > 0
                  ? item.images[0]
                  : item.image || 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=100&q=80';
                return (
                  <div key={item.id} className="summary-product-item">
                    <img src={img} alt={item.name} className="summary-prod-thumb" />
                    <div className="summary-prod-info">
                      <h4 className="summary-prod-name">{item.name}</h4>
                      <span className="summary-prod-qty">Qty: {item.quantity}</span>
                    </div>
                    <span className="summary-prod-price">{formatPrice(item.price * item.quantity)}</span>
                  </div>
                );
              })}
            </div>

            <div className="summary-cost-breakdown">
              <div className="summary-cost-row">
                <span>Subtotal</span>
                <span>{formatPrice(totalPrice)}</span>
              </div>
              <div className="summary-cost-row">
                <span>Delivery Charge</span>
                <span>{deliveryCharge === 0 ? 'Free' : formatPrice(deliveryCharge)}</span>
              </div>
              <div className="summary-cost-row grand-total-row">
                <strong>Total</strong>
                <strong>{formatPrice(grandTotal)}</strong>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Checkout;
