import React from 'react';
import { Link } from 'react-router-dom';
import './About.css';

const stats = [
  { number: '500+', label: 'Happy Customers' },
  { number: '1000+', label: 'Unique Designs' },
  { number: '100%', label: 'Certified Jewellery' },
  { number: '5 ★', label: 'Customer Rating' },
];

const promises = [
  { icon: '✦', title: 'Fine Craftsmanship', desc: 'Every piece is hand-crafted by our skilled artisans with decades of experience.' },
  { icon: '✦', title: 'Hallmarked Jewellery', desc: 'All our jewellery is certified and hallmarked for quality assurance.' },
  { icon: '✦', title: 'Ethical Sourcing', desc: 'We source our materials responsibly with care for the environment.' },
  { icon: '✦', title: 'Customer-first Service', desc: 'Your satisfaction is our top priority, from selection to delivery.' },
];

const About = () => {
  return (
    <div className="about-page page-content">
      {/* Header */}
      <div className="page-header about-header">
        <div className="container">
          <h1 className="page-header-title">About Us</h1>
          <p className="page-header-label">Crafted with Passion, Made to Celebrate You.</p>
        </div>
      </div>

      {/* Story Section */}
      <section className="about-story">
        <div className="container about-story-inner">
          <div className="about-image-wrap">
            <img
              src="https://images.unsplash.com/photo-1610694955371-d4a3e0ce4b52?w=800&q=85"
              alt="Sayuka Jewellery craftsmanship"
              className="about-main-image"
            />
          </div>
          <div className="about-text">
            <p className="section-label">Jewellery that feels like you</p>
            <h2 className="about-title">Welcome to Sayuka</h2>
            <p className="about-desc">
              Sayuka was born from a shared love for jewellery, fashion and the little details that can transform a look.
            </p>
            <p className="about-desc">
              Founded by sisters Soukya and Sneha, Sayuka is a jewellery brand built around pieces that make getting dressed a little more exciting — whether you’re dressing up for a celebration, putting together a special occasion look, or simply adding something extra to your everyday style.
            </p>
            <p className="about-desc">
              Our collections are thoughtfully curated to bring together pieces that feel beautiful, versatile and easy to style, so you can find something that feels just right for you.
            </p>
            <p className="about-desc">
              Because we don’t think jewellery should only be saved for special occasions. Sometimes, all it takes is the right pair of earrings, a necklace or a little sparkle to make you feel that much more put together.
            </p>
            <p className="about-desc">
              At Sayuka, we’re here to help you find those pieces — the ones you reach for again and again, and the ones that make you say, “Okay, this is the look.”
            </p>
          </div>
        </div>
      </section>

      {/* Stats */}
      <section className="about-stats">
        <div className="container">
          <div className="about-stats-grid">
            {stats.map((s, i) => (
              <div key={i} className="about-stat">
                <span className="about-stat-number">{s.number}</span>
                <span className="about-stat-label">{s.label}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Our Promise */}
      <section className="our-promise">
        <div className="container">
          <div className="text-center">
            <h2 className="section-title">Our Promise</h2>
            <div className="section-divider"><span>◆</span></div>
          </div>
          <div className="promise-grid">
            {promises.map((p, i) => (
              <div key={i} className="promise-card">
                <div className="promise-icon">{p.icon}</div>
                <h3 className="promise-title">{p.title}</h3>
                <p className="promise-desc">{p.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="about-cta">
        <div className="container">
          <div className="about-cta-inner">
            <p className="section-label">Explore Our Work</p>
            <h2 className="about-cta-title">Find Your Perfect Piece</h2>
            <p className="about-cta-desc">
              Browse our curated collection of handcrafted jewellery.
            </p>
            <div className="about-cta-actions">
              <Link to="/collections" className="btn btn-white btn-lg">Explore Collections</Link>
              <Link to="/custom-jewellery" className="btn btn-outline btn-lg" style={{ borderColor: 'rgba(255,255,255,0.5)', color: 'white' }}>Custom Jewellery</Link>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};

export default About;
