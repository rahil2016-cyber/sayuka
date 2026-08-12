import React from 'react';
import { Link } from 'react-router-dom';
import './CustomJewellery.css';

const steps = [
  { num: '01', title: 'Design Consultation', desc: 'Share your vision, reference images, or sketch with our experts.' },
  { num: '02', title: 'Design Proposal', desc: 'Our artisans create a detailed design proposal for your approval.' },
  { num: '03', title: 'Crafting Your Piece', desc: 'Once approved, our skilled craftsmen bring your jewellery to life.' },
  { num: '04', title: 'Delivery', desc: 'Your bespoke jewellery is delivered securely to your doorstep.' },
];

const CustomJewellery = () => {
  return (
    <div className="custom-page page-content">
      {/* Hero */}
      <section className="custom-hero">
        <div className="custom-hero-overlay" />
        <div className="container custom-hero-content">
          <p className="section-label" style={{ color: 'var(--color-gold)' }}>Bespoke Jewellery</p>
          <h1 className="custom-hero-title">Bring Your Vision<br />to Life</h1>
          <p className="custom-hero-desc">
            At Sayuka, we craft jewellery as unique as you. Work with our master artisans to create a piece that tells your story.
          </p>
          <a href="#custom-form" className="btn btn-primary btn-lg">Request a Quote</a>
        </div>
        <div className="custom-hero-image">
          <img src="https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800&q=85" alt="Custom jewellery" />
        </div>
      </section>

      {/* Process */}
      <section className="custom-process">
        <div className="container">
          <div className="text-center">
            <p className="section-label">How It Works</p>
            <h2 className="section-title">Our Custom Process</h2>
            <div className="section-divider"><span>◆</span></div>
          </div>
          <div className="process-grid">
            {steps.map((step, i) => (
              <div key={i} className="process-step">
                <div className="step-number">{step.num}</div>
                <h3 className="step-title">{step.title}</h3>
                <p className="step-desc">{step.desc}</p>
                {i < steps.length - 1 && <div className="step-arrow">→</div>}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Advantages */}
      <section className="custom-advantages">
        <div className="container">
          <div className="advantages-inner">
            <div className="advantages-image">
              <img
                src="https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=700&q=85"
                alt="Custom jewellery craftsmanship"
              />
            </div>
            <div className="advantages-text">
              <p className="section-label">Why Choose Custom?</p>
              <h2 className="advantages-title">Let's Create Something<br />Beautiful Together</h2>
              <p className="advantages-desc">
                Every love story, celebration, and milestone is unique. Your jewellery should be too.
              </p>
              <ul className="advantages-list">
                <li>✦ Personalized Design</li>
                <li>✦ Premium Craftsmanship</li>
                <li>✦ Assured Quality</li>
                <li>✦ Timely Delivery</li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* Quote Form */}
      <section id="custom-form" className="custom-form-section">
        <div className="container">
          <div className="text-center">
            <p className="section-label">Get Started</p>
            <h2 className="section-title">Request a Quote</h2>
            <div className="section-divider"><span>◆</span></div>
          </div>
          <form className="custom-form" onSubmit={(e) => e.preventDefault()} id="quote-form">
            <div className="form-row">
              <div className="form-group">
                <label htmlFor="c-name" className="form-label">Your Name *</label>
                <input type="text" id="c-name" className="form-input" placeholder="Full name" required />
              </div>
              <div className="form-group">
                <label htmlFor="c-email" className="form-label">Email Address *</label>
                <input type="email" id="c-email" className="form-input" placeholder="your@email.com" required />
              </div>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label htmlFor="c-type" className="form-label">Jewellery Type *</label>
                <select id="c-type" className="form-select">
                  <option value="">Select type...</option>
                  <option>Necklace</option>
                  <option>Ring</option>
                  <option>Earrings</option>
                  <option>Bangle</option>
                  <option>Bracelet</option>
                  <option>Mangalsutra</option>
                </select>
              </div>
              <div className="form-group">
                <label htmlFor="c-budget" className="form-label">Approximate Budget</label>
                <select id="c-budget" className="form-select">
                  <option value="">Select budget range...</option>
                  <option>Under ₹10,000</option>
                  <option>₹10,000 – ₹25,000</option>
                  <option>₹25,000 – ₹50,000</option>
                  <option>₹50,000 – ₹1,00,000</option>
                  <option>Above ₹1,00,000</option>
                </select>
              </div>
            </div>
            <div className="form-group">
              <label htmlFor="c-desc" className="form-label">Design Description *</label>
              <textarea
                id="c-desc"
                className="form-textarea"
                placeholder="Describe your dream jewellery piece in detail. Include style preferences, occasion, materials, stone preferences, etc."
                rows="5"
                required
              />
            </div>
            <button type="submit" className="btn btn-primary btn-lg custom-form-submit" id="quote-submit">
              Submit Quote Request
            </button>
          </form>
        </div>
      </section>

      {/* Trust badges */}
      <section className="custom-trust">
        <div className="container">
          <div className="custom-trust-grid">
            <div className="custom-trust-item">
              <span>✦</span>
              <span>Personalized Design</span>
            </div>
            <div className="custom-trust-item">
              <span>✦</span>
              <span>Assured Craftsmanship</span>
            </div>
            <div className="custom-trust-item">
              <span>✦</span>
              <span>Timely Delivery</span>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};

export default CustomJewellery;
