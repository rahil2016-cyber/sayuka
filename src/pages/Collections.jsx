import React, { useState, useEffect, useCallback } from 'react';
import { useSearchParams, Link } from 'react-router-dom';
import { productsAPI } from '../api';
import ProductCard from '../components/ProductCard';
import { categoryStructure, filterOptions } from '../data/categoriesData';
import './Collections.css';

const ITEMS_PER_PAGE = 8;

const Collections = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [mobileFilterOpen, setMobileFilterOpen] = useState(false);

  const activeCategory = searchParams.get('category') || 'all';
  const activeSort = searchParams.get('sort') || 'featured';
  const searchQuery = searchParams.get('search') || '';
  const activeMinPrice = searchParams.get('minPrice') || '';
  const activeMaxPrice = searchParams.get('maxPrice') || '';

  const fetchProducts = useCallback(async () => {
    setLoading(true);
    try {
      const params = {};
      if (activeCategory !== 'all') params.category = activeCategory;
      if (activeSort !== 'featured') params.sort = activeSort;
      if (searchQuery) params.search = searchQuery;
      if (activeMinPrice) params.minPrice = activeMinPrice;
      if (activeMaxPrice) params.maxPrice = activeMaxPrice;

      const res = await productsAPI.getAll(params);
      setProducts(res.data.data || []);
    } catch {
      setProducts([]);
    } finally {
      setLoading(false);
    }
  }, [activeCategory, activeSort, searchQuery, activeMinPrice, activeMaxPrice]);

  useEffect(() => {
    fetchProducts();
    setPage(1);
  }, [fetchProducts]);

  const updateParam = (key, value) => {
    const params = new URLSearchParams(searchParams);
    if (!value || value === 'all' || value === 'featured') {
      params.delete(key);
    } else {
      params.set(key, value);
    }
    setSearchParams(params);
  };

  const setPriceFilter = (min, max) => {
    const params = new URLSearchParams(searchParams);
    if (min !== undefined && min !== null) params.set('minPrice', min);
    else params.delete('minPrice');
    if (max !== undefined && max !== null) params.set('maxPrice', max);
    else params.delete('maxPrice');
    setSearchParams(params);
  };

  const clearAllFilters = () => {
    setSearchParams(new URLSearchParams());
  };

  const paginatedProducts = products.slice((page - 1) * ITEMS_PER_PAGE, page * ITEMS_PER_PAGE);
  const totalPages = Math.ceil(products.length / ITEMS_PER_PAGE);

  return (
    <div className="collections-page page-content">
      {/* Header Banner */}
      <div className="page-header collections-header">
        <div className="container">
          <p className="page-header-label">Shopify Experience • Sayuka Jewellery</p>
          <h1 className="page-header-title">
            {searchQuery ? `Search Results for "${searchQuery}"` : 'All Collections & Categories'}
          </h1>
          <p className="collections-sub">
            Explore 92.5 Silver, Gold-Plated, Jadau, Antique, and Fashion Jewellery
          </p>
        </div>
      </div>

      <div className="container collections-container">
        {/* Mobile Filter Drawer Button */}
        <div className="mobile-filter-bar mobile-only">
          <button className="btn btn-secondary mobile-filter-btn" onClick={() => setMobileFilterOpen(true)}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/></svg>
            Filter &amp; Categories
          </button>

          <select
            value={activeSort}
            onChange={(e) => updateParam('sort', e.target.value)}
            className="sort-select-mobile"
          >
            <option value="featured">Sort by: Featured</option>
            <option value="price_asc">Price: Low to High</option>
            <option value="price_desc">Price: High to Low</option>
            <option value="rating">Highest Rated</option>
          </select>
        </div>

        <div className="collections-layout">
          {/* Left Sidebar Filters (Desktop & Mobile Drawer) */}
          <aside className={`collections-sidebar ${mobileFilterOpen ? 'mobile-open' : ''}`}>
            <div className="sidebar-header mobile-only">
              <h3>Filters &amp; Categories</h3>
              <button className="close-btn" onClick={() => setMobileFilterOpen(false)}>×</button>
            </div>

            {/* Category Filter Tree */}
            <div className="filter-group">
              <h4 className="filter-title">Categories</h4>
              <ul className="filter-cat-list">
                <li>
                  <button
                    className={`filter-cat-btn ${activeCategory === 'all' ? 'active' : ''}`}
                    onClick={() => { updateParam('category', 'all'); setMobileFilterOpen(false); }}
                  >
                    <span>All Products</span>
                    <span className="count-dot">•</span>
                  </button>
                </li>

                {categoryStructure.map((section, idx) => (
                  <li key={idx} className="filter-section-block">
                    <span className="filter-section-title">{section.title}</span>
                    <ul className="filter-sub-list">
                      {section.items.map((item, itemIdx) => (
                        <li key={itemIdx}>
                          <button
                            className={`filter-cat-btn ${activeCategory === item.slug ? 'active' : ''}`}
                            onClick={() => { updateParam('category', item.slug); setMobileFilterOpen(false); }}
                          >
                            <span>{item.name}</span>
                          </button>
                          {item.subcategories && (
                            <ul className="filter-sub-accessories-list">
                              {item.subcategories.map((subGrp, gIdx) => (
                                <React.Fragment key={gIdx}>
                                  {subGrp.items.map((subItem, sbIdx) => (
                                    <li key={sbIdx}>
                                      <button
                                        className={`filter-cat-btn sub ${activeCategory === subItem.slug ? 'active' : ''}`}
                                        onClick={() => { updateParam('category', subItem.slug); setMobileFilterOpen(false); }}
                                      >
                                        └ {subItem.name}
                                      </button>
                                    </li>
                                  ))}
                                </React.Fragment>
                              ))}
                            </ul>
                          )}
                        </li>
                      ))}
                    </ul>
                  </li>
                ))}
              </ul>
            </div>

            {/* Price Filter Options */}
            <div className="filter-group">
              <h4 className="filter-title">Filter by Price</h4>
              <div className="price-options">
                <button
                  className={`price-chip ${!activeMinPrice && !activeMaxPrice ? 'active' : ''}`}
                  onClick={() => setPriceFilter(null, null)}
                >
                  All Prices
                </button>
                {filterOptions.priceRanges.map((range, idx) => (
                  <button
                    key={idx}
                    className={`price-chip ${parseInt(activeMinPrice) === range.min && parseInt(activeMaxPrice) === range.max ? 'active' : ''}`}
                    onClick={() => { setPriceFilter(range.min, range.max); setMobileFilterOpen(false); }}
                  >
                    {range.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Clear All */}
            {(activeCategory !== 'all' || activeSort !== 'featured' || searchQuery || activeMinPrice || activeMaxPrice) && (
              <button className="btn btn-outline btn-sm clear-btn" onClick={clearAllFilters}>
                Clear All Filters
              </button>
            )}
          </aside>

          {/* Main Product Grid */}
          <main className="collections-main">
            {/* Top Toolbar */}
            <div className="collections-toolbar desktop-only">
              <p className="products-count">
                Showing <strong>{products.length}</strong> products
              </p>
              <div className="toolbar-right">
                <label htmlFor="sort-select">Sort by:</label>
                <select
                  id="sort-select"
                  value={activeSort}
                  onChange={(e) => updateParam('sort', e.target.value)}
                  className="sort-select"
                >
                  <option value="featured">Featured</option>
                  <option value="price_asc">Price: Low to High</option>
                  <option value="price_desc">Price: High to Low</option>
                  <option value="rating">Highest Rated</option>
                </select>
              </div>
            </div>

            {/* Products */}
            {loading ? (
              <div className="loading-spinner" />
            ) : paginatedProducts.length === 0 ? (
              <div className="no-products">
                <h3>No jewellery found</h3>
                <p>Try clearing filters or searching for something else.</p>
                <button className="btn btn-primary" onClick={clearAllFilters}>Reset Filters</button>
              </div>
            ) : (
              <>
                <div className="products-grid">
                  {paginatedProducts.map(product => (
                    <ProductCard key={product.id} product={product} />
                  ))}
                </div>

                {/* Pagination */}
                {totalPages > 1 && (
                  <div className="pagination">
                    <button
                      className="page-btn"
                      disabled={page === 1}
                      onClick={() => setPage(p => p - 1)}
                    >
                      ‹ Previous
                    </button>
                    {[...Array(totalPages)].map((_, i) => (
                      <button
                        key={i}
                        className={`page-number ${page === i + 1 ? 'active' : ''}`}
                        onClick={() => setPage(i + 1)}
                      >
                        {i + 1}
                      </button>
                    ))}
                    <button
                      className="page-btn"
                      disabled={page === totalPages}
                      onClick={() => setPage(p => p + 1)}
                    >
                      Next ›
                    </button>
                  </div>
                )}
              </>
            )}
          </main>
        </div>
      </div>
    </div>
  );
};

export default Collections;
