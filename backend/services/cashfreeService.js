const { Cashfree, CFEnvironment } = require('cashfree-pg');

Cashfree.XClientId = process.env.CASHFREE_APP_ID;
Cashfree.XClientSecret = process.env.CASHFREE_SECRET_KEY;
Cashfree.XEnvironment = process.env.CASHFREE_ENVIRONMENT === 'production' ? CFEnvironment.PRODUCTION : CFEnvironment.SANDBOX;

const cashfree = new Cashfree();

class CashfreeService {
  async createPaymentSession(orderId, amount, customer) {
    try {
      const request = {
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
          // You could pass the frontend URL dynamically if needed
          return_url: "http://localhost:5173/checkout?order_id={order_id}"
        }
      };

      const response = await cashfree.PGCreateOrder(request);
      return response.data;
    } catch (error) {
      console.error('Error creating Cashfree payment session:', error.response?.data || error.message);
      throw error;
    }
  }
}

module.exports = new CashfreeService();
