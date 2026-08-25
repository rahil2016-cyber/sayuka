import React from 'react';
import './PrivacyPolicy.css';

const ShippingDelivery = () => {
  return (
    <div className="privacy-page page-content">
      <div className="container">
        <h1 className="page-title">Shipping & Delivery</h1>
        
        <div className="privacy-content">
          <h3>Order Processing</h3>
          <p>All orders are processed within 2-3 business days. Orders are not shipped or delivered on weekends or holidays.</p>

          <h3>Shipping Rates & Delivery Estimates</h3>
          <p>Shipping charges for your order will be calculated and displayed at checkout.</p>
          <ul>
            <li><strong>Standard Delivery:</strong> 3-5 business days</li>
            <li><strong>Express Delivery:</strong> 1-2 business days</li>
          </ul>
          <p>Delivery delays can occasionally occur due to unforeseen circumstances.</p>

          <h3>Order Tracking</h3>
          <p>Once your order is shipped, you will receive an email and WhatsApp message with tracking information.</p>

          <h3>Contact Us</h3>
          <address className="privacy-address">
            <strong>Sayuka</strong><br />
            <strong>Email:</strong> <a href="mailto:info@sayuka.in">info@sayuka.in</a><br />
            <strong>Address:</strong> Sayuka Jewellery, 169, 3rd main road, PJ Extension, Davanagere<br />
            <strong>Contact:</strong> <a href="tel:7090908555">7090908555</a>
          </address>
        </div>
      </div>
    </div>
  );
};

export default ShippingDelivery;
