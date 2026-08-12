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
            <p className="section-label">HERITAGE &amp; ARTISTRY</p>
            <h2 className="about-title">Crafting Memories in Gold &amp; Pure Silver</h2>
            <p className="about-desc">
              At Sayuka Jewellery, every design is a tribute to Indian heritage combined with modern aesthetic luxury. From 92.5 pure silver and gold-plated masterpieces to Victorian drops and Jadau bridal treasures.
            </p>
            <p className="about-desc">
              We blend traditional jewellery-making techniques with contemporary design to bring you pieces that are timeless yet modern. Each jewel is crafted with extraordinary attention to detail, ensuring 100% certified hallmarked purity with every creation.
            </p>
            <p className="about-desc">
              Founded with a passion for beauty and a commitment to craftsmanship, Sayuka has grown into a trusted name in fine jewellery. From delicate everyday pieces to grand statement collections, we have something for every occasion.
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
            <p className="section-label">Our Commitment</p>
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
