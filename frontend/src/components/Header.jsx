import React, { useState, useEffect, useRef } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useCart } from '../context/CartContext';
import { categoryStructure } from '../data/categoriesData';
import './Header.css';

const Header = () => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [activeDropdown, setActiveDropdown] = useState(null);
  const [activeSubDropdown, setActiveSubDropdown] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [expandedMobileCategories, setExpandedMobileCategories] = useState({});
  const { totalItems } = useCart();
  const location = useLocation();
  const navigate = useNavigate();
  const dropdownRef = useRef(null);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Close menus on route change
  useEffect(() => {
    setMobileMenuOpen(false);
    setActiveDropdown(null);
    setActiveSubDropdown(null);
  }, [location]);

  // Handle click outside dropdown
  useEffect(() => {
    const handleClickOutside = (e) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target)) {
        setActiveDropdown(null);
        setActiveSubDropdown(null);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleSearchSubmit = (e) => {
    e.preventDefault();
    if (searchQuery.trim()) {
      navigate(`/collections?search=${encodeURIComponent(searchQuery.trim())}`);
      setMobileMenuOpen(false);
    }
  };

  const toggleMobileCategory = (idx) => {
    setExpandedMobileCategories(prev => ({
      ...prev,
      [idx]: !prev[idx]
    }));
  };

  return (
    <header className="header-wrapper" ref={dropdownRef}>
      {/* Top Announcement Bar - Shopify Style */}
      <div className="topbar">
        <div className="container topbar-inner">
          <div className="topbar-ticker">
            <span>✨ Free Express Shipping on Orders Above ₹1,999</span>
            <span className="ticker-bullet">•</span>
            <span>100% Certified &amp; Hallmarked Jewellery</span>
            <span className="ticker-bullet">•</span>
            <span>Easy 7-Day Returns</span>
          </div>
          <div className="topbar-links">
            <a href="tel:+919876543210" className="topbar-phone">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor">
                <path d="M6.62 10.79a15.053 15.053 0 006.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z"/>
              </svg>
              +91 98765 43210
            </a>
            <span className="topbar-divider">|</span>
            <Link to="/contact">Track Order</Link>
          </div>
        </div>
      </div>

      {/* Main Navbar */}
      <nav className={`main-nav ${isScrolled ? 'scrolled' : ''}`}>
        <div className="container nav-container">

          {/* Left: Mobile Toggle & Logo */}
          <div className="nav-left">
            <button
              className="hamburger"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              aria-label="Toggle menu"
              id="header-mobile-toggle"
            >
              <span className={`bar ${mobileMenuOpen ? 'open' : ''}`} />
            </button>

            <Link to="/" className="logo-brand-link" id="header-logo">
              <img src="/logo.svg" alt="Sayuka Jewellery" className="header-logo-img" />
            </Link>
          </div>

          {/* Center: Desktop Navigation Bar with Mega Categories Dropdown */}
          <div className="nav-center desktop-only">
            <Link to="/" className={`nav-link ${location.pathname === '/' ? 'active' : ''}`}>
              Home
            </Link>

            {/* Categories Multi-Level Mega Dropdown */}
            <div
              className="nav-item-dropdown"
              onMouseEnter={() => setActiveDropdown('categories')}
            >
              <button className={`nav-link dropdown-trigger ${activeDropdown === 'categories' ? 'active' : ''}`}>
                Categories
                <svg className="dropdown-arrow" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                  <path d="M6 9l6 6 6-6"/>
                </svg>
              </button>

              {activeDropdown === 'categories' && (
                <div className="shopify-mega-dropdown" onMouseLeave={() => { setActiveDropdown(null); setActiveSubDropdown(null); }}>
                  <div className="mega-menu-grid">
                    {categoryStructure.map((catSection, sIdx) => (
                      <div key={sIdx} className="mega-column">
                        <h4 className="mega-title">{catSection.title}</h4>
                        <ul className="mega-list">
                          {catSection.items.map((item, iIdx) => (
                            <li key={iIdx} className="mega-item">
                              {item.subcategories ? (
                                <div
                                  className="mega-has-sub"
                                  onMouseEnter={() => setActiveSubDropdown(item.slug)}
                                >
                                  <Link
                                    to={`/collections?category=${item.slug}`}
                                    className="mega-link sub-trigger"
                                  >
                                    {item.name}
                                    <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M9 18l6-6-6-6"/></svg>
                                  </Link>

                                  {/* Sub-Accessories Popover */}
                                  {activeSubDropdown === item.slug && (
                                    <div className="sub-accessories-popover">
                                      {item.subcategories.map((subGrp, gIdx) => (
                                        <div key={gIdx} className="sub-group">
                                          <div className="sub-group-title">{subGrp.group}</div>
                                          {subGrp.items.map((subItem, sbIdx) => (
                                            <Link
                                              key={sbIdx}
                                              to={`/collections?category=${subItem.slug}`}
                                              className="sub-item-link"
                                            >
                                              {subItem.name}
                                            </Link>
                                          ))}
                                        </div>
                                      ))}
                                    </div>
                                  )}
                                </div>
                              ) : (
                                <Link
                                  to={`/collections?category=${item.slug}`}
                                  className="mega-link"
                                >
                                  {item.name}
                                </Link>
                              )}
                            </li>
                          ))}
                        </ul>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            <Link to="/about" className={`nav-link ${location.pathname === '/about' ? 'active' : ''}`}>
              About Us
            </Link>
            <Link to="/contact" className={`nav-link ${location.pathname === '/contact' ? 'active' : ''}`}>
              Contact
            </Link>
          </div>

          {/* Right: Search Bar & Actions (Shopify Style) */}
          <div className="nav-right">
            {/* Desktop Header Integrated Search Bar */}
            <form onSubmit={handleSearchSubmit} className="header-search-form desktop-only">
              <input
                type="text"
                placeholder="Search jewellery, rings..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="header-search-input"
              />
              <button type="submit" className="header-search-btn" aria-label="Search">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <circle cx="11" cy="11" r="8" />
                  <line x1="21" y1="21" x2="16.65" y2="16.65" />
                </svg>
              </button>
            </form>

            {/* Mobile Search Icon Toggle */}
            <button
              className="icon-btn search-toggle-mobile mobile-only"
              onClick={() => {
                const elem = document.getElementById('mobile-search-input');
                if (elem) elem.focus();
              }}
              aria-label="Search"
            >
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <circle cx="11" cy="11" r="8" />
                <line x1="21" y1="21" x2="16.65" y2="16.65" />
              </svg>
            </button>

            {/* Cart Icon Drawer Trigger */}
            <Link to="/cart" className="icon-btn cart-btn" aria-label="Cart" id="header-cart-btn">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
                <path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z" />
                <line x1="3" y1="6" x2="21" y2="6" />
                <path d="M16 10a4 4 0 01-8 0" />
              </svg>
              {totalItems > 0 && <span className="cart-badge">{totalItems}</span>}
            </Link>
          </div>

        </div>

        {/* Mobile Search Bar Row (Under Header on Mobile) */}
        <div className="mobile-search-container mobile-only">
          <form onSubmit={handleSearchSubmit} className="mobile-search-form">
            <input
              id="mobile-search-input"
              type="text"
              placeholder="Search necklaces, earrings, 92.5 silver..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
            <button type="submit" aria-label="Search">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <circle cx="11" cy="11" r="8" />
                <line x1="21" y1="21" x2="16.65" y2="16.65" />
              </svg>
            </button>
          </form>
        </div>
      </nav>

      {/* Mobile Slide-Out Navigation Drawer */}
      <div className={`mobile-drawer-overlay ${mobileMenuOpen ? 'active' : ''}`} onClick={() => setMobileMenuOpen(false)} />
      <aside className={`mobile-drawer ${mobileMenuOpen ? 'open' : ''}`}>
        <div className="mobile-drawer-header">
          <Link to="/" onClick={() => setMobileMenuOpen(false)}>
            <img src="/logo.svg" alt="Sayuka Jewellery" className="mobile-logo-img" />
          </Link>
          <button className="close-btn" onClick={() => setMobileMenuOpen(false)}>
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <line x1="18" y1="6" x2="6" y2="18"/>
              <line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>

        <div className="mobile-drawer-body">
          <div className="mobile-menu-section-title">WEBSITE CATEGORIES</div>

          {categoryStructure.map((catSection, sIdx) => (
            <div key={sIdx} className="mobile-cat-accordion">
              <button
                className="mobile-accordion-header"
                onClick={() => toggleMobileCategory(sIdx)}
              >
                <span>{catSection.title}</span>
                <svg
                  className={`accordion-chevron ${expandedMobileCategories[sIdx] ? 'open' : ''}`}
                  width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
                >
                  <path d="M6 9l6 6 6-6"/>
                </svg>
              </button>

              {expandedMobileCategories[sIdx] && (
                <ul className="mobile-accordion-content">
                  {catSection.items.map((item, iIdx) => (
                    <li key={iIdx}>
                      <Link
                        to={`/collections?category=${item.slug}`}
                        onClick={() => setMobileMenuOpen(false)}
                        className="mobile-sub-link"
                      >
                        {item.name}
                      </Link>

                      {item.subcategories && (
                        <div className="mobile-sub-accessories">
                          {item.subcategories.map((subGrp, gIdx) => (
                            <div key={gIdx} className="mobile-sub-grp">
                              <span className="grp-label">{subGrp.group}:</span>
                              {subGrp.items.map((subItem, sbIdx) => (
                                <Link
                                  key={sbIdx}
                                  to={`/collections?category=${subItem.slug}`}
                                  onClick={() => setMobileMenuOpen(false)}
                                  className="grp-item-tag"
                                >
                                  {subItem.name}
                                </Link>
                              ))}
                            </div>
                          ))}
                        </div>
                      )}
                    </li>
                  ))}
                </ul>
              )}
            </div>
          ))}

          <div className="mobile-drawer-divider" />

          <ul className="mobile-primary-links">
            <li><Link to="/about" onClick={() => setMobileMenuOpen(false)}>About Us</Link></li>
            <li><Link to="/contact" onClick={() => setMobileMenuOpen(false)}>Contact Us</Link></li>
          </ul>
        </div>
      </aside>
    </header>
  );
};

export default Header;
