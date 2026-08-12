import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import './App.css';
import { CartProvider } from './context/CartContext';
import Header from './components/Header';
import Footer from './components/Footer';
import Home from './pages/Home';
import Collections from './pages/Collections';
import ProductDetail from './pages/ProductDetail';
import About from './pages/About';
import CustomJewellery from './pages/CustomJewellery';
import Contact from './pages/Contact';
import Cart from './pages/Cart';
import Admin from './pages/Admin';
import './index.css';

// Scroll to top on route change
const ScrollToTop = () => {
  React.useEffect(() => {
    window.scrollTo(0, 0);
  }, []);
  return null;
};

const AppLayout = () => {
  return (
    <div className="app-layout">
      <Header />
      <main>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/collections" element={<Collections />} />
          <Route path="/product/:id" element={<ProductDetail />} />
          <Route path="/about" element={<About />} />
          <Route path="/custom-jewellery" element={<CustomJewellery />} />
          <Route path="/contact" element={<Contact />} />
          <Route path="/cart" element={<Cart />} />
          <Route path="*" element={<NotFound />} />
        </Routes>
      </main>
      <Footer />
    </div>
  );
};

const App = () => {
  return (
    <Router>
      <CartProvider>
        <Routes>
          <Route path="/admin/*" element={<Admin />} />
          <Route path="/*" element={<AppLayout />} />
        </Routes>
      </CartProvider>
    </Router>
  );
};

const NotFound = () => (
  <div className="page-content" style={{
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: '60vh',
    textAlign: 'center',
    gap: '1.5rem'
  }}>
    <div style={{ fontSize: '5rem', color: 'var(--color-gold)', fontFamily: 'var(--font-heading)' }}>404</div>
    <h2 style={{ fontFamily: 'var(--font-heading)', fontSize: '2rem', color: 'var(--color-deep-purple)' }}>Page Not Found</h2>
    <p style={{ color: 'var(--color-text-muted)' }}>The page you are looking for doesn't exist.</p>
    <a href="/" className="btn btn-primary">Go to Homepage</a>
  </div>
);

export default App;
