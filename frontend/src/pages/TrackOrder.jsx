import React, { useState, useEffect } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { adminAPI } from '../api';
import './TrackOrder.css';

const STATUS_STEPS = ['Pending', 'Processing', 'Shipped', 'Delivered'];

const TrackOrder = () => {
  const [searchParams] = useSearchParams();
  const [orderId, setOrderId] = useState(searchParams.get('id') || '');
  const [inputId, setInputId] = useState(searchParams.get('id') || '');
  const [result, setResult] = useState(null);
  const [history, setHistory] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (searchParams.get('id')) {
      handleTrack(searchParams.get('id'));
    }
  }, []);

  const handleTrack = async (id = inputId) => {
    const trimmed = (id || inputId).trim();
    if (!trimmed) return;
    setLoading(true);
    setError('');
    setResult(null);
    setHistory(null);

    const isContact = trimmed.includes('@') || /^\d{8,15}$/.test(trimmed.replace(/\s+/g, ''));

    try {
      if (isContact) {
        const res = await adminAPI.trackHistory(trimmed);
        if (res.data.success) {
          if (res.data.data.length === 0) {
            setError('No orders found for this contact information.');
          } else {
            setHistory(res.data.data);
          }
        }
      } else {
        const res = await adminAPI.trackOrder(trimmed);
        if (res.data.success) {
          setResult(res.data.data);
          setOrderId(trimmed);
        }
      }
    } catch (err) {
      if (err.response?.status === 404) {
        setError('❌ Order not found. Please double-check your tracking code.');
      } else {
        setError('Something went wrong. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    handleTrack(inputId);
  };

  const getStepIndex = (status) => {
    if (status === 'Cancelled') return -1;
    return STATUS_STEPS.findIndex(s => s === status);
  };

  const formatDate = (dateStr) => {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit' });
  };

  const stepIndex = result ? getStepIndex(result.orderStatus) : -1;
  const isCancelled = result?.orderStatus === 'Cancelled';

  return (
    <div className="track-order-page page-content">
      <div className="track-container">

        {/* Header */}
        <div className="track-header">
          <div className="track-icon-wrap">
            <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
              <rect x="1" y="3" width="15" height="13" rx="2"/>
              <path d="M16 8h4l3 5v3h-7V8z"/>
              <circle cx="5.5" cy="18.5" r="2.5"/>
              <circle cx="18.5" cy="18.5" r="2.5"/>
            </svg>
          </div>
          <h1 className="track-title">Track Your Order</h1>
          <p className="track-subtitle">Enter your Order ID, Email, or Phone Number to view your orders</p>
        </div>

        {/* Search Form */}
        <form className="track-search-form" onSubmit={handleSubmit}>
          <div className="track-input-row">
            <input
              type="text"
              className="track-input"
              placeholder="Order ID, Email, or Phone (e.g. #SAYUKA... or 9876543210)"
              value={inputId}
              onChange={e => setInputId(e.target.value)}
              required
            />
            <button type="submit" className="btn btn-primary track-btn" disabled={loading}>
              {loading ? (
                <span className="track-spinner" />
              ) : (
                <>
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
                  </svg>
                  Track
                </>
              )}
            </button>
          </div>
          {error && <div className="track-error">{error}</div>}
        </form>

        {/* History Result */}
        {history && (
          <div className="track-history-list">
            <h2 className="track-history-title">Your Orders</h2>
            <div className="track-history-cards">
              {history.map(order => (
                <div key={order.id} className="track-history-card">
                  <div className="track-history-card-header">
                    <div className="track-history-id">{order.id}</div>
                    <div className="track-history-date">{formatDate(order.created_at || order.createdAt)}</div>
                  </div>
                  <div className="track-history-card-body">
                    <div className="track-history-status">
                      Status: <span className={`track-payment-badge ${order.order_status?.toLowerCase() || order.orderStatus?.toLowerCase()}`}>{order.order_status || order.orderStatus}</span>
                    </div>
                    <div className="track-history-total">
                      Total: ₹{parseFloat(order.total_amount || order.totalAmount).toLocaleString('en-IN')}
                    </div>
                  </div>
                  <button className="btn btn-primary track-history-btn" onClick={() => {
                    setInputId(order.id);
                    handleTrack(order.id);
                  }}>Track Order</button>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Single Result */}
        {result && !history && (
          <div className="track-result-card">
            <div className="track-result-top">
              <div>
                <div className="track-result-label">Order ID</div>
                <div className="track-result-id">{result.id}</div>
              </div>
              <div>
                <div className="track-result-label">Placed on</div>
                <div className="track-result-date">{formatDate(result.createdAt)}</div>
              </div>
              <div>
                <div className="track-result-label">Customer</div>
                <div className="track-result-name">{result.customerName}</div>
              </div>
              <div>
                <div className="track-result-label">Total</div>
                <div className="track-result-amount">₹{parseFloat(result.totalAmount).toLocaleString('en-IN')}</div>
              </div>
            </div>

            {/* Status Timeline */}
            {isCancelled ? (
              <div className="track-cancelled-banner">
                ⚠️ This order has been <strong>Cancelled</strong>. Please contact us for support.
              </div>
            ) : (
              <div className="track-timeline">
                {STATUS_STEPS.map((step, idx) => {
                  const isDone = idx <= stepIndex;
                  const isActive = idx === stepIndex;
                  return (
                    <div key={step} className={`track-step ${isDone ? 'done' : ''} ${isActive ? 'active' : ''}`}>
                      <div className="step-dot-wrap">
                        <div className="step-dot">
                          {isDone && (
                            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="3">
                              <polyline points="20 6 9 17 4 12"/>
                            </svg>
                          )}
                        </div>
                        {idx < STATUS_STEPS.length - 1 && <div className="step-line" />}
                      </div>
                      <div className="step-label">
                        <span className="step-name">{step}</span>
                        {isActive && <span className="step-badge">Current</span>}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}

            {/* Items */}
            {result.items && result.items.length > 0 && (
              <div className="track-items-section">
                <div className="track-items-title">Order Items ({result.itemCount})</div>
                <div className="track-items-list">
                  {result.items.map((item, i) => (
                    <div key={i} className="track-item-row" style={{ display: 'flex', alignItems: 'center', gap: '1rem', padding: '0.5rem 0' }}>
                      {item.image ? (
                        <img src={item.image} alt={item.name} style={{ width: '48px', height: '48px', objectFit: 'cover', borderRadius: '4px' }} />
                      ) : (
                        <div style={{ width: '48px', height: '48px', backgroundColor: '#f3f4f6', borderRadius: '4px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" strokeWidth="2"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
                        </div>
                      )}
                      <span className="track-item-name" style={{ flex: 1 }}>{item.name}</span>
                      <span className="track-item-qty">× {item.qty}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Payment Badge */}
            <div className="track-payment-row">
              <span className="track-payment-label">Payment:</span>
              <span className={`track-payment-badge ${result.paymentStatus?.toLowerCase()}`}>
                {result.paymentStatus}
              </span>
            </div>
          </div>
        )}

        {/* Help text */}
        {!result && !loading && (
          <div className="track-help">
            <p>🔍 Your <strong>Order ID</strong> was shown on your order confirmation screen after checkout.</p>
            <p>Need help? <Link to="/contact" className="track-contact-link">Contact us</Link></p>
          </div>
        )}

      </div>
    </div>
  );
};

export default TrackOrder;
