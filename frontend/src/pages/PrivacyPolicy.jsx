import React from 'react';
import './PrivacyPolicy.css';

const PrivacyPolicy = () => {
  return (
    <div className="privacy-page page-content">
      <div className="container">
        <h1 className="page-title">Privacy Policy</h1>
        
        <div className="privacy-content">
          <p>At Sayuka, we respect your privacy and are committed to protecting your personal information.</p>
          <p>When you visit our website or place an order, we may collect information such as your name, phone number, email address, billing and shipping address, order details and information required to process your payment.</p>
          
          <h3>How We Use Your Information</h3>
          <p>We use your information to:</p>
          <ul>
            <li>Process and deliver your orders</li>
            <li>Process payments, returns and refunds</li>
            <li>Communicate with you about your orders</li>
            <li>Respond to customer enquiries</li>
            <li>Improve our website, products and services</li>
            <li>Send promotional updates and offers, where permitted</li>
            <li>Prevent fraud and comply with applicable laws</li>
          </ul>

          <h3>Sharing Your Information</h3>
          <p>We do not sell your personal information.</p>
          <p>We may share necessary information with trusted service providers such as payment gateways, delivery partners, technology providers and other service providers who help us operate Sayuka and fulfil your orders.</p>
          <p>We may also share information where required by law or by a lawful government authority.</p>

          <h3>Cookies</h3>
          <p>Our website may use cookies and similar technologies to improve website functionality, understand how visitors use our website and provide a better browsing experience.</p>

          <h3>Marketing Communications</h3>
          <p>If you have opted to receive promotional communications from us, we may contact you through email, SMS, WhatsApp or other available channels. You may opt out of promotional communications at any time.</p>

          <h3>Data Security</h3>
          <p>We take reasonable measures to protect your personal information from unauthorised access, misuse or disclosure. However, no online system can be guaranteed to be completely secure.</p>

          <h3>Your Information</h3>
          <p>If you have questions about your personal information or wish to make a privacy-related request, please contact us at:</p>

          <address className="privacy-address">
            <strong>Sayuka</strong><br />
            <strong>Email:</strong> <a href="mailto:info@sayuka.in">info@sayuka.in</a><br />
            <strong>Address:</strong> Sayuka Jewellery, 169, 3rd main road, PJ Extension, Davanagere<br />
            <strong>Contact:</strong> <a href="tel:7090908555">7090908555</a>
          </address>

          <p>We may update this Privacy Policy from time to time. Any changes will be posted on this page with an updated date.</p>
        </div>
      </div>
    </div>
  );
};

export default PrivacyPolicy;
