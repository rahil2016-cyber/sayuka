import axios from 'axios';

// In production, frontend is served by Express so we use relative /api path.
// In development, VITE_API_URL from .env is used (e.g. http://localhost:5000/api).
const API_URL = import.meta.env.VITE_API_URL || '/api';

const api = axios.create({
  baseURL: API_URL,
  timeout: 10000,
  withCredentials: true,
});

export const productsAPI = {
  getAll: (params = {}) => api.get('/products', { params }),
  getBestsellers: () => api.get('/products/bestsellers'),
  getById: (id) => api.get(`/products/${id}`),
  create: (data) => api.post('/products', data),
  update: (id, data) => api.put(`/products/${id}`, data),
  delete: (id) => api.delete(`/products/${id}`),
};

export const adminAPI = {
  login: (credentials) => api.post('/admin/login', credentials),
  logout: () => api.post('/admin/logout'),
  verify: () => api.get('/admin/verify'),
  getOrders: () => api.get('/admin/orders'),
  createOrder: (data) => api.post('/admin/orders', data),
  createPaymentSession: (data) => api.post('/admin/orders/create-payment-session', data),
  updateOrderStatus: (id, status) => api.put(`/admin/orders/${encodeURIComponent(id)}/status`, { status }),
  trackOrder: (orderId) => api.get(`/admin/track/${encodeURIComponent(orderId)}`),
  trackHistory: (contact) => api.get(`/admin/track/history?contact=${encodeURIComponent(contact)}`),
  getBanners: () => api.get('/admin/banners'),
  createBanner: (data) => api.post('/admin/banners', data),
  deleteBanner: (id) => api.delete(`/admin/banners/${id}`),
  getCategories: () => api.get('/admin/categories'),
  createCategory: (data) => api.post('/admin/categories', data),
  updateCategory: (id, data) => api.put(`/admin/categories/${id}`, data),
  deleteCategory: (id) => api.delete(`/admin/categories/${id}`),
};

export const contactAPI = {
  send: (data) => api.post('/contact', data),
};

export default api;
