import React from 'react';
import './PrivacyPolicy.css';

const ReturnsExchanges = () => {
  return (
    <div className="privacy-page page-content">
      <div className="container">
        <h1 className="page-title">Returns & Exchanges</h1>
        
        <div className="privacy-content">
          <h3>Return Policy</h3>
          <p>We want you to be completely satisfied with your purchase. You may return unused and undamaged items within 7 days of delivery for a full refund or exchange.</p>

          <h3>Eligibility for Returns</h3>
          <ul>
            <li>Items must be unworn and in their original condition.</li>
            <li>Original packaging, tags, and certificates must be intact.</li>
            <li>Customised or engraved jewellery is not eligible for returns.</li>
          </ul>

          <h3>How to Initiate a Return</h3>
          <p>Please contact our support team to initiate a return. We will provide you with a return shipping label and instructions.</p>

          <h3>Refunds</h3>
          <p>Once we receive and inspect your returned item, we will process your refund within 5-7 business days to your original payment method.</p>

          <h3>Contact Us</h3>
          <address className="privacy-address">
            <strong>Sayuka</strong><br />
            <strong>Email:</strong> <a href="mailto:info@sayuka.in">info@sayuka.in</a><br />
            <strong>Contact:</strong> <a href="tel:7090908555">7090908555</a>
          </address>
        </div>
      </div>
    </div>
  );
};

export default ReturnsExchanges;
