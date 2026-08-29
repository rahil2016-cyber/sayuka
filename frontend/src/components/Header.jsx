import React, { useState, useEffect, useRef } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useCart } from '../context/CartContext';
import { useWishlist } from '../context/WishlistContext';
import { productsAPI } from '../api';
import { categoryStructure } from '../data/categoriesData';
import './Header.css';

const Header = () => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [activeDropdown, setActiveDropdown] = useState(null);
  const [activeSubDropdown, setActiveSubDropdown] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState([]);
  const [showSearchResults, setShowSearchResults] = useState(false);
  const [isMobileSearchOpen, setIsMobileSearchOpen] = useState(false);
  const [expandedMobileCategories, setExpandedMobileCategories] = useState({});
  const { totalItems } = useCart();
  const { wishlistItems } = useWishlist();
  const location = useLocation();
  const navigate = useNavigate();
  const dropdownRef = useRef(null);
  const searchRef = useRef(null);
  const mobileSearchRef = useRef(null);

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
    setShowSearchResults(false);
    setSearchQuery('');
  }, [location]);

  // Handle click outside dropdown & search results
  useEffect(() => {
    const handleClickOutside = (e) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target)) {
        setActiveDropdown(null);
        setActiveSubDropdown(null);
      }
      if (
        (searchRef.current && !searchRef.current.contains(e.target)) &&
        (mobileSearchRef.current && !mobileSearchRef.current.contains(e.target))
      ) {
        setShowSearchResults(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Instant Search Autocomplete
  useEffect(() => {
    if (!searchQuery.trim()) {
      setSearchResults([]);
      setShowSearchResults(false);
      return;
    }

    const delayDebounceFn = setTimeout(async () => {
      try {
        const res = await productsAPI.getAll({ search: searchQuery.trim() });
        setSearchResults(res.data.data ? res.data.data.slice(0, 5) : []); // limit to 5 suggestions
        setShowSearchResults(true);
      } catch (err) {
        console.error('Instant search error:', err);
      }
    }, 300);

    return () => clearTimeout(delayDebounceFn);
  }, [searchQuery]);

  const handleSearchSubmit = (e) => {
    e.preventDefault();
    if (searchQuery.trim()) {
      navigate(`/collections?search=${encodeURIComponent(searchQuery.trim())}`);
      setMobileMenuOpen(false);
      setShowSearchResults(false);
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
      {/* Top Announcement Bar — Live Scrolling Marquee */}
      <div className="topbar">
        <div className="topbar-marquee-wrap">
          <div className="topbar-marquee">
            <span>✨ Free Express Shipping on Orders Above ₹4,999</span>
            <span className="ticker-bullet">•</span>
            <span>100% Certified &amp; Hallmarked Jewellery</span>
            <span className="ticker-bullet">•</span>
            <span>Easy 5-Day Returns</span>
            <span className="ticker-bullet">•</span>
            <span>📞 Call us: 7090908555</span>
            <span className="ticker-bullet">•</span>
            <span>✨ Free Express Shipping on Orders Above ₹4,999</span>
            <span className="ticker-bullet">•</span>
            <span>100% Certified &amp; Hallmarked Jewellery</span>
            <span className="ticker-bullet">•</span>
            <span>Easy 5-Day Returns</span>
            <span className="ticker-bullet">•</span>
            <span>📞 Call us: 7090908555</span>
            <span className="ticker-bullet">•</span>
          </div>
        </div>
      </div>

      {/* Main Navbar */}
      <nav className={`main-nav ${isScrolled ? 'scrolled' : ''}`}>
        <div className="container nav-container">

          {/* Left: Mobile Toggle & Logo */}
          <div className="nav-left">
            <button
              className={`hamburger ${mobileMenuOpen ? 'open' : ''}`}
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              aria-label="Toggle menu"
              id="header-mobile-toggle"
            >
              <span className="bar bar-top" />
              <span className="bar bar-mid" />
              <span className="bar bar-bot" />
            </button>

            <Link to="/" className="logo-brand-link" id="header-logo">
              <img 
                src="/images/sayuka-logo.png" 
                alt="Sayuka Jewellery" 
                className="sayuka-logo" 
              />
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
            <Link to="/track-order" className={`nav-link ${location.pathname === '/track-order' ? 'active' : ''}`}>
              Track Order
            </Link>
            <Link to="/contact" className={`nav-link ${location.pathname === '/contact' ? 'active' : ''}`}>
              Contact
            </Link>
          </div>

          {/* Right: Search Bar & Actions (Shopify Style) */}
          <div className="nav-right">
            {/* Desktop Header Integrated Search Bar */}
            <div className="header-search-form-wrapper desktop-only" ref={searchRef}>
              <form onSubmit={handleSearchSubmit} className="header-search-form">
                <input
                  type="text"
                  placeholder="Search jewellery, rings..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  onFocus={() => searchQuery.trim() && setShowSearchResults(true)}
                  className="header-search-input"
                />
                <button type="submit" className="header-search-btn" aria-label="Search">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <circle cx="11" cy="11" r="8" />
                    <line x1="21" y1="21" x2="16.65" y2="16.65" />
                  </svg>
                </button>
              </form>

              {/* Instant Search Suggestions Dropdown */}
              {showSearchResults && searchResults.length > 0 && (
                <div className="instant-search-dropdown">
                  <div className="search-dropdown-header">Products suggestion</div>
                  <ul className="search-dropdown-list">
                    {searchResults.map((product) => {
                      const img = Array.isArray(product.images) && product.images.length > 0
                        ? product.images[0]
                        : product.image || 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=100&q=80';
                      return (
                        <li key={product.id} className="search-dropdown-item">
                          <Link to={`/product/${product.id}`} className="search-dropdown-link" onClick={() => setShowSearchResults(false)}>
                            <img src={img} alt={product.name} className="search-suggest-thumb" />
                            <div className="search-suggest-info">
                              <span className="search-suggest-name">{product.name}</span>
                              <span className="search-suggest-price">₹{Number(product.price).toLocaleString('en-IN')}</span>
                            </div>
                          </Link>
                        </li>
                      );
                    })}
                  </ul>
                  <div className="search-dropdown-footer">
                    <button type="button" onClick={handleSearchSubmit} className="search-view-all">
                      View all results for "{searchQuery}" &rarr;
                    </button>
                  </div>
                </div>
              )}
            </div>

            {/* Mobile Search Icon */}
            <button 
              className="icon-btn mobile-only" 
              onClick={() => setIsMobileSearchOpen(!isMobileSearchOpen)}
              aria-label="Toggle Search"
            >
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
                <circle cx="11" cy="11" r="8" />
                <line x1="21" y1="21" x2="16.65" y2="16.65" />
              </svg>
            </button>

            {/* Wishlist Heart Icon Trigger */}
            <Link to="/wishlist" className="icon-btn wishlist-btn" aria-label="Wishlist" id="header-wishlist-btn">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                <path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z"/>
              </svg>
              {wishlistItems.length > 0 && <span className="cart-badge" style={{ backgroundColor: '#ff4757', color: '#fff' }}>{wishlistItems.length}</span>}
            </Link>

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
        {isMobileSearchOpen && (
          <div className="mobile-search-container mobile-only" ref={mobileSearchRef}>
          <form onSubmit={handleSearchSubmit} className="mobile-search-form">
            <input
              id="mobile-search-input"
              type="text"
              placeholder="Search necklaces, earrings, 92.5 silver..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onFocus={() => searchQuery.trim() && setShowSearchResults(true)}
            />
            <button type="submit" aria-label="Search">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <circle cx="11" cy="11" r="8" />
                <line x1="21" y1="21" x2="16.65" y2="16.65" />
              </svg>
            </button>
          </form>

          {/* Mobile Autocomplete suggestion list */}
          {showSearchResults && searchResults.length > 0 && (
            <div className="instant-search-dropdown mobile-only">
              <ul className="search-dropdown-list">
                {searchResults.map((product) => {
                  const img = Array.isArray(product.images) && product.images.length > 0
                    ? product.images[0]
                    : product.image || 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=100&q=80';
                  return (
                    <li key={product.id} className="search-dropdown-item">
                      <Link to={`/product/${product.id}`} className="search-dropdown-link" onClick={() => setShowSearchResults(false)}>
                        <img src={img} alt={product.name} className="search-suggest-thumb" />
                        <div className="search-suggest-info">
                          <span className="search-suggest-name">{product.name}</span>
                          <span className="search-suggest-price">₹{Number(product.price).toLocaleString('en-IN')}</span>
                        </div>
                      </Link>
                    </li>
                  );
                })}
              </ul>
            </div>
          )}
        </div>
        )}
      </nav>

      {/* Mobile Slide-Out Navigation Drawer */}
      <div className={`mobile-drawer-overlay ${mobileMenuOpen ? 'active' : ''}`} onClick={() => setMobileMenuOpen(false)} />
      <aside className={`mobile-drawer ${mobileMenuOpen ? 'open' : ''}`}>
        <div className="mobile-drawer-header">
          <Link to="/" onClick={() => setMobileMenuOpen(false)}>
            <img 
              src="/images/sayuka-logo.png" 
              alt="Sayuka Jewellery" 
              className="sayuka-logo sayuka-logo-mobile" 
            />
          </Link>
          <button className="close-btn" onClick={() => setMobileMenuOpen(false)}>
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <line x1="18" y1="6" x2="6" y2="18"/>
              <line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>

        <div className="mobile-drawer-body">
          <div className="mobile-drawer-home-link-wrap" style={{ marginBottom: '1.25rem' }}>
            <Link
              to="/"
              onClick={() => setMobileMenuOpen(false)}
              style={{
                display: 'block',
                fontSize: '1rem',
                fontWeight: '700',
                color: '#fff',
                textDecoration: 'none',
                textTransform: 'uppercase',
                letterSpacing: '0.08em',
                padding: '8px 0',
                borderBottom: '1px solid rgba(255,255,255,0.1)'
              }}
            >
              🏠 Home
            </Link>
          </div>

          <div className="mobile-menu-section-title">JEWELLERY CATEGORIES</div>

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
            <li><Link to="/track-order" onClick={() => setMobileMenuOpen(false)}>📦 Track Order</Link></li>
          </ul>
        </div>
      </aside>
    </header>
  );
};

export default Header;
