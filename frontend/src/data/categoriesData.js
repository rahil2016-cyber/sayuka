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
  },
  {
    title: "Gold Plated 92.5 Silver Jewellery",
    slug: "gold-plated-925-silver",
    items: [
      { name: "Gold-Plated Necklace", slug: "gold-plated-necklace" },
      { name: "Gold-Plated Earrings", slug: "gold-plated-earrings" },
      { name: "Gold-Plated Pendant Sets", slug: "gold-plated-pendant-sets" },
      { name: "Gold-Plated Bracelets", slug: "gold-plated-bracelets" },
      { name: "Gold-Plated Accessories", slug: "gold-plated-accessories" },
      { name: "Gold-Plated Rings", slug: "gold-plated-rings" },
      { name: "Gold-Plated Chains", slug: "gold-plated-chains" }
    ]
  },
  {
    title: "92.5 Silver Jewellery",
    slug: "925-silver-jewellery",
    items: [
      { name: "Silver Earrings", slug: "silver-earrings" },
      { name: "Silver Chains", slug: "silver-chains" },
      { name: "Silver Pendant Sets", slug: "silver-pendant-sets" },
      { name: "Silver Bracelets", slug: "silver-bracelets" },
      { name: "Silver Rings", slug: "silver-rings" },
      { name: "Silver Toe rings", slug: "silver-toe-rings" },
      { name: "Silver Accessories", slug: "silver-accessories" }
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
