const axios = require('axios');

class CashfreeService {
  async createPaymentSession(orderId, amount, customer) {
    try {
      const isProd = process.env.CASHFREE_ENVIRONMENT === 'production';
      const baseURL = isProd ? 'https://api.cashfree.com/pg' : 'https://sandbox.cashfree.com/pg';

      const requestPayload = {
        order_amount: amount,
        order_currency: "INR",
        order_id: orderId,
        customer_details: {
          customer_id: customer.phone ? customer.phone.replace(/[^0-9]/g, '') : 'CUST' + Date.now(),
          customer_phone: customer.phone,
          customer_email: customer.email,
          customer_name: customer.name
        },
        order_meta: {
          return_url: "http://localhost:5173/checkout?order_id={order_id}"
        }
      };

      const response = await axios.post(`${baseURL}/orders`, requestPayload, {
        headers: {
          'x-client-id': process.env.CASHFREE_APP_ID,
          'x-client-secret': process.env.CASHFREE_SECRET_KEY,
          'x-api-version': '2023-08-01',
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }
      });

      return response.data;
    } catch (error) {
      console.error('Error creating Cashfree payment session:', error.response?.data || error.message);
      throw error;
    }
  }
}

module.exports = new CashfreeService();
