import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000/api';

const api = axios.create({
  baseURL: API_URL,
  timeout: 10000,
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
  getOrders: () => api.get('/admin/orders'),
  updateOrderStatus: (id, status) => api.put(`/admin/orders/${id}/status`, { status }),
  getBanners: () => api.get('/admin/banners'),
  createBanner: (data) => api.post('/admin/banners', data),
  deleteBanner: (id) => api.delete(`/admin/banners/${id}`),
};

export const contactAPI = {
  send: (data) => api.post('/contact', data),
};

export default api;
