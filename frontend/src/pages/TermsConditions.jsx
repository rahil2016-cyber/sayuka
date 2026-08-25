import React from 'react';
import './PrivacyPolicy.css';

const TermsConditions = () => {
  return (
    <div className="privacy-page page-content">
      <div className="container">
        <h1 className="page-title">Terms & Conditions</h1>
        
        <div className="privacy-content">
          <h3>Introduction</h3>
          <p>Welcome to Sayuka. By accessing our website and purchasing our products, you agree to be bound by the following terms and conditions.</p>

          <h3>Use of the Website</h3>
          <p>You may use our website for lawful purposes only. You must not use our website in any way that causes, or may cause, damage to the website or impairment of the availability or accessibility of the website.</p>

          <h3>Product Information</h3>
          <p>We make every effort to display as accurately as possible the colors and details of our products. However, we cannot guarantee that your device's display of any color will be accurate.</p>

          <h3>Pricing and Payments</h3>
          <p>All prices are subject to change without notice. We reserve the right to modify or discontinue any product without notice.</p>
          <p>We accept various payment methods through secure gateways. You agree to provide current, complete, and accurate purchase and account information for all purchases made at our store.</p>

          <h3>Intellectual Property</h3>
          <p>All content included on this site, such as text, graphics, logos, images, and software, is the property of Sayuka or its content suppliers and protected by international copyright laws.</p>

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

export default TermsConditions;
