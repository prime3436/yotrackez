// Nutrition Database for NutriSnap (YOTRACKEZ)
const NUTRITION_DATABASE = [
  { id: 'avocado_toast', name: 'Avocado Toast with Egg', category: 'Breakfast', calories: 350, protein: 14, carbs: 28, fat: 22, fiber: 7, serving: '1 slice (180g)', icon: '🥑' },
  { id: 'oatmeal_berries', name: 'Berry & Honey Oatmeal', category: 'Breakfast', calories: 280, protein: 9, carbs: 52, fat: 4, fiber: 8, serving: '1 bowl (250g)', icon: '🥣' },
  { id: 'greek_yogurt_granola', name: 'Greek Yogurt Parfait', category: 'Breakfast', calories: 240, protein: 18, carbs: 30, fat: 5, fiber: 3, serving: '1 cup (200g)', icon: '🫐' },
  { id: 'scrambled_eggs', name: 'Scrambled Eggs & Spinach', category: 'Breakfast', calories: 220, protein: 16, carbs: 3, fat: 16, fiber: 1, serving: '2 eggs (150g)', icon: '🍳' },
  { id: 'pancakes_syrup', name: 'Maple Pancakes (2 pcs)', category: 'Breakfast', calories: 410, protein: 8, carbs: 72, fat: 10, fiber: 2, serving: '2 pancakes (180g)', icon: '🥞' },

  { id: 'grilled_chicken_salad', name: 'Grilled Chicken Caesar Salad', category: 'Lunch', calories: 380, protein: 38, carbs: 12, fat: 20, fiber: 4, serving: '1 plate (320g)', icon: '🥗' },
  { id: 'salmon_quinoa', name: 'Grilled Salmon with Quinoa', category: 'Dinner', calories: 520, protein: 42, carbs: 36, fat: 22, fiber: 5, serving: '1 fillet + side (350g)', icon: '🐟' },
  { id: 'chicken_breast_rice', name: 'Chicken Breast & Brown Rice', category: 'Lunch', calories: 460, protein: 45, carbs: 48, fat: 7, fiber: 4, serving: '1 meal (380g)', icon: '🍗' },
  { id: 'cheeseburger', name: 'Classic Beef Cheeseburger', category: 'Fast Food', calories: 560, protein: 28, carbs: 44, fat: 30, fiber: 2, serving: '1 burger (220g)', icon: '🍔' },
  { id: 'margherita_pizza', name: 'Margherita Pizza', category: 'Fast Food', calories: 680, protein: 26, carbs: 82, fat: 28, fiber: 4, serving: '2 slices (260g)', icon: '🍕' },
  { id: 'sushi_roll_combo', name: 'Salmon & Avocado Sushi Roll', category: 'Dinner', calories: 410, protein: 22, carbs: 58, fat: 9, fiber: 3, serving: '8 rolls (240g)', icon: '🍣' },
  { id: 'pasta_bolognese', name: 'Spaghetti Bolognese', category: 'Dinner', calories: 590, protein: 29, carbs: 75, fat: 19, fiber: 5, serving: '1 plate (380g)', icon: '🍝' },

  { id: 'protein_shake', name: 'Whey Protein Shake', category: 'Beverage', calories: 180, protein: 26, carbs: 6, fat: 3, fiber: 1, serving: '1 scoop + milk (350ml)', icon: '🥤' },
  { id: 'green_smoothie', name: 'Detox Green Smoothie', category: 'Beverage', calories: 190, protein: 5, carbs: 40, fat: 2, fiber: 6, serving: '1 glass (300ml)', icon: '🥤' },
  { id: 'apple', name: 'Fresh Red Apple', category: 'Snack', calories: 95, protein: 0.5, carbs: 25, fat: 0.3, fiber: 4.4, serving: '1 medium (182g)', icon: '🍎' },
  { id: 'banana', name: 'Ripe Banana', category: 'Snack', calories: 105, protein: 1.3, carbs: 27, fat: 0.3, fiber: 3.1, serving: '1 medium (118g)', icon: '🍌' },
  { id: 'mixed_nuts', name: 'Roasted Almonds & Walnuts', category: 'Snack', calories: 210, protein: 7, carbs: 8, fat: 18, fiber: 4, serving: '1 handful (35g)', icon: '🥜' },
  { id: 'dark_chocolate', name: '70% Dark Chocolate', category: 'Snack', calories: 170, protein: 2.2, carbs: 13, fat: 12, fiber: 3.1, serving: '3 squares (30g)', icon: '🍫' }
];

// Search helper
function searchNutritionDb(query) {
  if (!query) return NUTRITION_DATABASE;
  const q = query.toLowerCase().trim();
  return NUTRITION_DATABASE.filter(item => 
    item.name.toLowerCase().includes(q) || 
    item.category.toLowerCase().includes(q)
  );
}

// Simulate AI Recognition from Image / Sample Keywords
function simulateAiFoodScan(filenameOrKeyword = '') {
  const kw = filenameOrKeyword.toLowerCase();
  if (kw.includes('burger') || kw.includes('fast')) return NUTRITION_DATABASE.find(x => x.id === 'cheeseburger');
  if (kw.includes('salad') || kw.includes('green')) return NUTRITION_DATABASE.find(x => x.id === 'grilled_chicken_salad');
  if (kw.includes('pizza')) return NUTRITION_DATABASE.find(x => x.id === 'margherita_pizza');
  if (kw.includes('sushi') || kw.includes('fish')) return NUTRITION_DATABASE.find(x => x.id === 'sushi_roll_combo');
  if (kw.includes('egg') || kw.includes('avocado')) return NUTRITION_DATABASE.find(x => x.id === 'avocado_toast');
  if (kw.includes('shake') || kw.includes('protein')) return NUTRITION_DATABASE.find(x => x.id === 'protein_shake');

  // Random sample fallback if unspecified
  const idx = Math.floor(Math.random() * NUTRITION_DATABASE.length);
  return NUTRITION_DATABASE[idx];
}
