const axios = require('axios');

class CashfreeService {
  async createPaymentSession(orderId, amount, customer) {
    try {
      const isProd = process.env.CASHFREE_ENVIRONMENT === 'production';
      const baseURL = isProd ? 'https://api.cashfree.com/pg' : 'https://sandbox.cashfree.com/pg';

      const appId = (process.env.CASHFREE_APP_ID || '').trim();
      const secret = (process.env.CASHFREE_SECRET_KEY || '').trim();

      console.log(`[Cashfree Debug] Environment: ${process.env.CASHFREE_ENVIRONMENT}`);
      console.log(`[Cashfree Debug] App ID prefix: ${appId.substring(0, 5)}... (Length: ${appId.length})`);
      console.log(`[Cashfree Debug] Secret prefix: ${secret.substring(0, 5)}... (Length: ${secret.length})`);

      if (!appId || !secret) {
        throw new Error('Cashfree credentials are missing in the environment variables!');
      }

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
          return_url: `${process.env.FRONTEND_URL || 'https://sayuka.in'}/checkout?order_id={order_id}`
        }
      };

      const response = await axios.post(`${baseURL}/orders`, requestPayload, {
        headers: {
          'x-client-id': appId,
          'x-client-secret': secret,
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
