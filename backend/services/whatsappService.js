const axios = require('axios');

class WhatsAppService {
  constructor() {
    this.phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID;
    this.accessToken = process.env.WHATSAPP_ACCESS_TOKEN;
    this.apiUrl = `https://graph.facebook.com/v17.0/${this.phoneNumberId}/messages`;
  }

  isConfigured() {
    return !!(this.phoneNumberId && this.accessToken);
  }

  async sendMessage(to, templateName, components = []) {
    if (!this.isConfigured()) {
      console.log('WhatsApp Service not configured. Skipping message to:', to);
      return false;
    }

    try {
      const payload = {
        messaging_product: 'whatsapp',
        to: to,
        type: 'template',
        template: {
          name: templateName,
          language: {
            code: 'en_US'
          },
          components: components
        }
      };

      const response = await axios.post(this.apiUrl, payload, {
        headers: {
          'Authorization': `Bearer ${this.accessToken}`,
          'Content-Type': 'application/json'
        }
      });

      console.log('WhatsApp message sent successfully:', response.data);
      return true;
    } catch (error) {
      console.error('Error sending WhatsApp message:', error.response?.data || error.message);
      return false;
    }
  }

  // Common notification templates
  async sendOrderConfirmation(to, orderId, customerName) {
    // Requires a template named 'order_confirmation' with 2 variables in the body
    return this.sendMessage(to, 'order_confirmation', [
      {
        type: 'body',
        parameters: [
          { type: 'text', text: customerName },
          { type: 'text', text: orderId }
        ]
      }
    ]);
  }

  async sendOrderShipped(to, orderId, trackingLink) {
     // Requires a template named 'order_shipped' with 2 variables in the body
    return this.sendMessage(to, 'order_shipped', [
      {
        type: 'body',
        parameters: [
          { type: 'text', text: orderId },
          { type: 'text', text: trackingLink || 'N/A' }
        ]
      }
    ]);
  }

  async sendOrderDelivered(to, orderId) {
     // Requires a template named 'order_delivered' with 1 variable in the body
    return this.sendMessage(to, 'order_delivered', [
      {
        type: 'body',
        parameters: [
          { type: 'text', text: orderId }
        ]
      }
    ]);
  }
}

module.exports = new WhatsAppService();
