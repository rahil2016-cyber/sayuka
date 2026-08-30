import React, { useState, useEffect, useRef } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { productsAPI, adminAPI } from '../api';
import ProductCard from '../components/ProductCard';
import './Home.css';

const defaultHeroSlides = [
  {
    id: 1,
    image: 'https://images.unsplash.com/photo-1610694955371-d4a3e0ce4b52?w=1600&q=95',
    title: 'Timeless Heritage Collection',
    subtitle: 'Handcrafted gold plated 92.5 silver & Jadau sets'
  },
  {
    id: 2,
    image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=1600&q=95',
    title: 'Modern CZ & Diamond Sparkle',
    subtitle: 'Brilliant craftsmanship designed to shine for every occasion'
  },
  {
    id: 3,
    image: 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=1600&q=95',
    title: 'Anti-Tarnish Everyday Luxury',
    subtitle: 'Waterproof, durable, and effortlessly elegant'
  },
];

const defaultCategoryCards = [
  {
    id: 1,
    name: 'Necklaces',
    slug: 'necklaces',
    image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80'
  },
  {
    id: 2,
    name: 'Earrings',
    slug: 'earrings',
    image: 'https://images.unsplash.com/photo-1635767798638-3e25273a8236?w=600&q=80'
  },
  {
    id: 3,
    name: 'Pendant Sets',
    slug: 'pendant-sets',
    image: 'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=600&q=80'
  },
  {
    id: 4,
    name: 'Bangles & Bracelets',
    slug: 'bangles-bracelets',
    image: 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=600&q=80'
  },
  {
    id: 5,
    name: 'Rings',
    slug: 'rings',
    image: 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=600&q=80'
  },
  {
    id: 6,
    name: 'Maangtika',
    slug: 'maangtika',
    image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=600&q=80'
  },
  {
    id: 7,
    name: 'Gold Plated',
    slug: 'gold-plated-necklace',
    image: 'https://images.unsplash.com/photo-1610694955371-d4a3e0ce4b52?w=600&q=80'
  }
];

const fallbackBestsellers = [
  {
    id: 1,
    name: "Eternal Bloom Pendant",
    price: 1899,
    originalPrice: 2499,
    category: "necklaces",
    images: ["https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80"],
    badge: "Bestseller",
    isBestseller: true
  },
  {
    id: 2,
    name: "Pearl Drop Earrings",
    price: 1499,
    originalPrice: 1999,
    category: "earrings",
    images: ["https://images.unsplash.com/photo-1635767798638-3e25273a8236?w=600&q=80"],
    badge: null,
    isBestseller: true
  },
  {
    id: 3,
    name: "Twilight Ring",
    price: 1699,
    originalPrice: 2199,
    category: "rings",
    images: ["https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=600&q=80"],
    badge: "Bestseller",
    isBestseller: true
  },
  {
    id: 4,
    name: "Classic Tennis Bracelet",
    price: 2299,
    originalPrice: 2999,
    category: "bangles",
    images: ["https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=600&q=80"],
    badge: null,
    isBestseller: true
  }
];

const filterTabs = ['All', 'Necklaces', 'Earrings', 'Rings', 'Bangles'];

const Home = () => {
  const [currentSlide, setCurrentSlide] = useState(0);
  const [heroSlides, setHeroSlides] = useState(defaultHeroSlides);
  const [bestsellers, setBestsellers] = useState(fallbackBestsellers);
  const [newArrivals, setNewArrivals] = useState([]);
  const [categoryCards, setCategoryCards] = useState(defaultCategoryCards);
  const [activeTab, setActiveTab] = useState('All');
  const [loading, setLoading] = useState(true);
  const sliderRef = useRef(null);
  const slideTimer = useRef(null);
  const navigate = useNavigate();

  useEffect(() => {
    adminAPI.getBanners().then(res => {
      if (res.data.data && res.data.data.length > 0) {
        setHeroSlides(res.data.data);
      } else {
        setHeroSlides(defaultHeroSlides);
      }
    }).catch(() => {
      setHeroSlides(defaultHeroSlides);
    });

    // Fetch shop categories from backend
    adminAPI.getCategories().then(res => {
      if (res.data.data && res.data.data.length > 0) {
        const mergedCategories = res.data.data.map(dbCat => {
          const defaultCat = defaultCategoryCards.find(d => d.slug === dbCat.slug);
          return {
            ...dbCat,
            image: dbCat.image || defaultCat?.image || 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=600&q=80'
          };
        });
        setCategoryCards(mergedCategories);
      }
    }).catch(() => {
      setCategoryCards(defaultCategoryCards);
    });
  }, []);

  useEffect(() => {
    if (heroSlides.length === 0) return;
    slideTimer.current = setInterval(() => {
      setCurrentSlide(prev => (prev + 1) % heroSlides.length);
    }, 5000);
    return () => clearInterval(slideTimer.current);
  }, [heroSlides]);

  useEffect(() => {
    const fetchHomeProducts = async () => {
      try {
        setLoading(true);
        // Fetch bestsellers
        const bestRes = await productsAPI.getBestsellers();
        if (bestRes.data.data && bestRes.data.data.length > 0) {
          setBestsellers(bestRes.data.data);
        }

        // Fetch all products to determine New Arrivals (prioritize isNewArrival flag)
        const allRes = await productsAPI.getAll();
        if (allRes.data.data && allRes.data.data.length > 0) {
          const flaggedNew = allRes.data.data.filter(p => p.isNewArrival);
          if (flaggedNew.length > 0) {
            setNewArrivals(flaggedNew.slice(0, 4));
          } else {
            const sorted = [...allRes.data.data].sort((a, b) => b.id - a.id);
            setNewArrivals(sorted.slice(0, 4));
          }
        }
      } catch (err) {
        console.error('Error fetching home products:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchHomeProducts();
  }, []);

  const handlePrevSlide = () => {
    setCurrentSlide(prev => (prev === 0 ? heroSlides.length - 1 : prev - 1));
  };

  const handleNextSlide = () => {
    setCurrentSlide(prev => (prev + 1) % heroSlides.length);
  };

  const handleScrollSlider = (direction) => {
    if (sliderRef.current) {
      const scrollAmount = direction === 'left' ? -300 : 300;
      sliderRef.current.scrollBy({ left: scrollAmount, behavior: 'smooth' });
    }
  };

  const filteredProducts = bestsellers.filter(product => {
    if (activeTab === 'All') return true;
    const cat = (product.category || '').toLowerCase();
    const tab = activeTab.toLowerCase();
    if (tab === 'bangles') return cat.includes('bangles') || cat.includes('bracelet');
    if (tab === 'necklaces') return cat.includes('necklace') || cat.includes('pendant');
    return cat.includes(tab);
  });

  return (
    <div className="sayuka-homepage-wrapper">
      {/* HERO BANNER SECTION */}
      {heroSlides.length > 0 && (
        <section className="hero-banner-single">
          <div className="hero-slides-wrapper">
            {heroSlides.map((slide, idx) => (
              <div key={slide.id} className={`hero-slide ${idx === currentSlide ? 'active' : ''}`}>
                <img src={slide.image} alt={slide.title} className="hero-banner-img" />
              </div>
            ))}
          </div>
        </section>
      )}

      {/* SECTION 1: Shop by Category */}
      <section className="luxury-category-section">
        <div className="container relative-container">
          
          {/* Section Header */}
          <div className="luxury-header text-center">
            <p className="luxury-subtitle">EXPLORE THE COLLECTION</p>
            <h2 className="luxury-title">Shop by Category</h2>
            <div className="luxury-divider">
              <span className="divider-line"></span>
              <span className="diamond-motif">✦</span>
              <span className="divider-line"></span>
            </div>
          </div>

          {/* Category Carousel */}
          <div className="category-slider-wrapper">
            <button
              className="slider-arrow-btn left-arrow"
              onClick={() => handleScrollSlider('left')}
              aria-label="Previous categories"
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#2D122D" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                <polyline points="15 18 9 12 15 6"></polyline>
              </svg>
            </button>

            <div className="category-slider-track" ref={sliderRef}>
              {categoryCards.map((cat) => (
                <div
                  key={cat.id || cat.slug}
                  className="category-card-item"
                  onClick={() => navigate(`/collections?category=${cat.slug}`)}
                >
                  <div className="category-card-img-wrap">
                    <img src={cat.image} alt={cat.name} loading="lazy" />
                    <div className="category-card-overlay" />
                    <div className="category-card-caption">
                      <h3 className="category-card-title">{cat.name}</h3>
                      <span className="category-card-link">
                        Explore collection &rarr;
                      </span>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            <button
              className="slider-arrow-btn right-arrow"
              onClick={() => handleScrollSlider('right')}
              aria-label="Next categories"
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#2D122D" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                <polyline points="9 18 15 12 9 6"></polyline>
              </svg>
            </button>
          </div>

        </div>
      </section>

      {/* SECTION 1.5: New Arrivals */}
      {newArrivals.length > 0 && (
        <section className="luxury-new-arrivals-section" style={{ padding: '4rem 0', backgroundColor: '#fff', borderBottom: '1px solid rgba(230, 168, 80, 0.1)' }}>
          <div className="container relative-container">
            {/* Section Header */}
            <div className="luxury-header text-center">
              <p className="luxury-subtitle" style={{ fontSize: '0.75rem', letterSpacing: '0.2em', color: 'var(--color-gold)', fontWeight: '700', marginBottom: '0.5rem' }}>JUST INTRODUCED</p>
              <h2 className="luxury-title" style={{ fontFamily: 'var(--font-heading)', fontSize: '2.2rem', color: 'var(--color-deep-purple)', fontWeight: '400' }}>New Arrivals</h2>
              <div className="luxury-divider" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '1rem', marginTop: '0.5rem', marginBottom: '2rem' }}>
                <span className="divider-line" style={{ height: '1px', width: '50px', background: 'var(--color-gold)', opacity: '0.6' }}></span>
                <span className="diamond-motif" style={{ color: 'var(--color-gold)', fontSize: '0.8rem' }}>✦</span>
                <span className="divider-line" style={{ height: '1px', width: '50px', background: 'var(--color-gold)', opacity: '0.6' }}></span>
              </div>
            </div>

            {/* Product Cards Grid */}
            <div className="bestsellers-grid-container">
              {newArrivals.map((product) => (
                <ProductCard key={product.id} product={product} />
              ))}
            </div>

            {/* View All Button */}
            <div className="text-center view-all-wrap" style={{ marginTop: '2.5rem' }}>
              <Link to="/collections?sort=newest" className="view-all-bestsellers-btn">
                View All New Arrivals &rarr;
              </Link>
            </div>
          </div>
        </section>
      )}

      {/* SECTION 2: Our Bestsellers */}
      <section className="luxury-bestseller-section">
        <div className="container relative-container">
          
          {/* Section Header */}
          <div className="luxury-header text-center">
            <p className="luxury-subtitle">MOST LOVED PIECES</p>
            <h2 className="luxury-title">Our Bestsellers</h2>
            <div className="luxury-divider">
              <span className="divider-line"></span>
              <span className="diamond-motif">✦</span>
              <span className="divider-line"></span>
            </div>

            {/* Filter Tabs */}
            <div className="filter-tabs-row">
              {filterTabs.map((tab, idx) => (
                <React.Fragment key={tab}>
                  {idx > 0 && <span className="tab-separator">|</span>}
                  <button
                    className={`filter-tab-item ${activeTab === tab ? 'active' : ''}`}
                    onClick={() => setActiveTab(tab)}
                  >
                    {tab}
                  </button>
                </React.Fragment>
              ))}
            </div>
          </div>

          {/* Product Cards Grid */}
          {loading ? (
            <div className="luxury-loading">Loading Bestsellers...</div>
          ) : (
            <div className="bestsellers-grid-container">
              {filteredProducts.map(product => (
                <ProductCard key={product.id} product={product} />
              ))}
            </div>
          )}

          {/* View All Bestsellers Button */}
          <div className="text-center view-all-wrap">
            <Link to="/collections?filter=bestsellers" className="view-all-bestsellers-btn">
              View All Bestsellers &rarr;
            </Link>
          </div>

        </div>

        {/* Decorative Background Floral Line Art Watermark */}
        <div className="bg-floral-watermark" aria-hidden="true">
          <svg width="280" height="280" viewBox="0 0 200 200" fill="none" stroke="#E3D5C5" strokeWidth="0.8" opacity="0.6">
            <path d="M10 190 Q 50 140, 70 80 Q 90 20, 150 10 M 70 80 Q 110 90, 160 50 M 70 80 Q 40 40, 10 30 M 50 140 Q 90 150, 140 120 M 50 140 Q 10 120, 5 90 M 130 90 Q 170 110, 190 160" />
            <circle cx="150" cy="10" r="4" fill="#E3D5C5" opacity="0.4" />
            <circle cx="160" cy="50" r="5" fill="#E3D5C5" opacity="0.4" />
            <circle cx="140" cy="120" r="6" fill="#E3D5C5" opacity="0.4" />
          </svg>
        </div>
      </section>
    </div>
  );
};

export default Home;
