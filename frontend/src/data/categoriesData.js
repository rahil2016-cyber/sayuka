export const categoryStructure = [
  {
    title: "Fashion Jewellery",
    slug: "fashion-jewellery",
    items: [
      { name: "Necklaces", slug: "necklaces" },
      { name: "Earrings", slug: "earrings" },
      { name: "Pendant Sets", slug: "pendant-sets" },
      { name: "Bangles & Bracelets", slug: "bangles-bracelets" },
      { name: "Rings", slug: "rings" },
      {
        name: "Accessories",
        slug: "accessories",
        subcategories: [
          {
            group: "Hair accessories",
            items: [
              { name: "Maangtika", slug: "maangtika" },
              { name: "Matil", slug: "matil" },
              { name: "Brooch", slug: "brooch" }
            ]
          },
          {
            group: "Hand accessories",
            items: [
              { name: "Hathpans", slug: "hathpans" },
              { name: "Bajubandh", slug: "bajubandh" }
            ]
          },
          {
            group: "Other accessories",
            items: [
              { name: "Belt", slug: "belt" },
              { name: "Nath", slug: "nath" }
            ]
          }
        ]
      }
    ]
  },
  {
    title: "92.5 Silver Jewellery",
    slug: "925-silver-jewellery",
    items: [
      { name: "Delicate", slug: "delicate-silver" },
      { name: "Gold Plated", slug: "gold-plated-silver" }
    ]
  },
  {
    title: "Collections",
    slug: "collections",
    items: [
      { name: "Antique", slug: "antique" },
      { name: "CZ", slug: "cz" },
      { name: "Victorian", slug: "victorian" },
      { name: "Jadau", slug: "jadau" },
      { name: "Pearls", slug: "pearls" },
      { name: "Mangalsutra", slug: "mangalsutra" },
      { name: "Mother of Pearl", slug: "mother-of-pearl" },
      { name: "Anti-Tarnish", slug: "anti-tarnish" }
    ]
  }
];

export const filterOptions = {
  priceRanges: [
    { label: "Under ₹5,000", min: 0, max: 5000 },
    { label: "₹5,000 - ₹15,000", min: 5000, max: 15000 },
    { label: "₹15,000 - ₹30,000", min: 15000, max: 30000 },
    { label: "Above ₹30,000", min: 30000, max: 1000000 }
  ]
};
