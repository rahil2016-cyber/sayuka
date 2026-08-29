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

  const deliveryCharge = deliveryOption === 'home' ? (totalPrice > 0 && totalPrice < 4999 ? 200 : 0) : 0;
  const grandTotal = totalPrice + deliveryCharge;

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (items.length === 0) return;

    setIsSubmitting(true);
    try {
      const customer = {
        name: formData.name,
        email: formData.email,
        phone: formData.whatsapp,
      };

      // 1. Create a payment session in backend
      const sessionRes = await adminAPI.createPaymentSession({
        totalAmount: grandTotal,
        customer,
      });

      if (!sessionRes.data.success) {
        throw new Error('Failed to create payment session');
      }

      const { payment_session_id } = sessionRes.data;

      // 2. Initialize Cashfree
      if (!window.Cashfree) {
         throw new Error('Payment gateway failed to load');
      }
      
      const cashfree = window.Cashfree({
        mode: "sandbox", // Change to production when live
      });

      // 3. Open Checkout
      let checkoutOptions = {
        paymentSessionId: payment_session_id,
        redirectTarget: "_modal" 
      };

      cashfree.checkout(checkoutOptions).then(async (result) => {
        if(result.error){
            console.error("Payment failed", result.error);
            alert("Payment failed or cancelled!");
            setIsSubmitting(false);
        }
        if(result.paymentDetails){
            console.log("Payment success", result.paymentDetails);
            
            // 4. Create the final order on success
            const orderPayload = {
              customer,
              address: `${formData.address}, ${formData.city}, ${formData.state} - ${formData.pincode}`,
              items: items.map((item) => ({
                name: item.name,
                price: item.price,
                qty: item.quantity,
              })),
              totalAmount: grandTotal,
              paymentMethod: 'Cashfree',
              whatsappConsent: true
            };

            const res = await adminAPI.createOrder(orderPayload);
            if (res.data.success) {
              setOrderSuccess(res.data.data);
              clearCart();
            }
        }
      });
    } catch (err) {
      alert('Order placement failed: ' + (err.response?.data?.message || err.message));
      setIsSubmitting(false);
    } 
  };

  if (orderSuccess) {
    const trackUrl = `/track-order?id=${encodeURIComponent(orderSuccess.id)}`;
    return (
      <div className="checkout-page page-content text-center">
        <div className="container success-container">
          <div className="success-icon">🎉</div>
          <h1 className="success-title">Order Placed Successfully!</h1>
          <p style={{ color: 'var(--color-text-muted)', marginBottom: '1.5rem' }}>
            Thank you, <strong>{orderSuccess.customer.name}</strong>! We'll connect with you on WhatsApp (<strong>{orderSuccess.customer.phone}</strong>) shortly.
          </p>

          {/* Tracking Code Box */}
          <div className="tracking-code-box">
            <div className="tracking-code-label">🔖 Your Order Tracking Code</div>
            <div className="tracking-code-value">{orderSuccess.id}</div>
            <div className="tracking-code-hint">Save this code to track your order status anytime</div>
            <button
              className="copy-code-btn"
              onClick={() => {
                navigator.clipboard.writeText(orderSuccess.id);
                alert('Tracking code copied!');
              }}
            >
              📋 Copy Code
            </button>
          </div>

          <div className="success-amount">Total: {formatPrice(orderSuccess.totalAmount)}</div>

          <div className="success-actions">
            <Link to={trackUrl} className="btn btn-primary btn-lg">
              📦 Track My Order
            </Link>
            <Link to="/collections" className="btn btn-outline btn-lg">
              Continue Shopping
            </Link>
          </div>
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

            {/* Delivery Address */}
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
