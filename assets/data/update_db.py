import json

with open(r'C:\Users\HP\.gemini\antigravity\scratch\nutri_snap\assets\data\nutrition_db.json', 'r', encoding='utf-8') as f:
    db = json.load(f)

lookup = {item['id']: item for item in db}


ingredients_for_existing = {
    "chicken_curry": [
        {"name": "Chicken Thigh", "amount": "150g", "calories": 195, "carbs": 0, "protein": 20, "fat": 12, "fiber": 0},
        {"name": "Onion", "amount": "50g", "calories": 20, "carbs": 4.7, "protein": 0.6, "fat": 0.1, "fiber": 0.7},
        {"name": "Tomato", "amount": "60g", "calories": 11, "carbs": 2.4, "protein": 0.5, "fat": 0.1, "fiber": 0.7},
        {"name": "Cooking Oil", "amount": "10ml", "calories": 88, "carbs": 0, "protein": 0, "fat": 10, "fiber": 0},
        {"name": "Yogurt", "amount": "30g", "calories": 18, "carbs": 1.4, "protein": 1, "fat": 1, "fiber": 0},
        {"name": "Curry Spices", "amount": "5g", "calories": 15, "carbs": 2.5, "protein": 0.5, "fat": 0.5, "fiber": 1}
    ],
    "pad_thai": [
        {"name": "Rice Noodles", "amount": "150g", "calories": 190, "carbs": 44, "protein": 1.6, "fat": 0.4, "fiber": 0.9},
        {"name": "Shrimp", "amount": "60g", "calories": 60, "carbs": 0, "protein": 12, "fat": 1, "fiber": 0},
        {"name": "Egg", "amount": "50g", "calories": 72, "carbs": 0.4, "protein": 6.3, "fat": 5, "fiber": 0},
        {"name": "Bean Sprouts", "amount": "40g", "calories": 12, "carbs": 2.4, "protein": 1.2, "fat": 0.1, "fiber": 0.7},
        {"name": "Peanuts", "amount": "15g", "calories": 85, "carbs": 2.4, "protein": 3.9, "fat": 7.2, "fiber": 1.3},
        {"name": "Tamarind Sauce", "amount": "20g", "calories": 24, "carbs": 6, "protein": 0.2, "fat": 0, "fiber": 0.5},
        {"name": "Cooking Oil", "amount": "10ml", "calories": 88, "carbs": 0, "protein": 0, "fat": 10, "fiber": 0}
    ],
    "sushi": [
        {"name": "Sushi Rice", "amount": "150g", "calories": 195, "carbs": 43, "protein": 3.5, "fat": 0.3, "fiber": 0.6},
        {"name": "Nori Seaweed", "amount": "8g", "calories": 3, "carbs": 0.5, "protein": 0.5, "fat": 0, "fiber": 0.3},
        {"name": "Salmon/Tuna", "amount": "60g", "calories": 80, "carbs": 0, "protein": 13, "fat": 3, "fiber": 0},
        {"name": "Avocado", "amount": "30g", "calories": 48, "carbs": 2.6, "protein": 0.6, "fat": 4.4, "fiber": 2},
        {"name": "Cucumber", "amount": "20g", "calories": 3, "carbs": 0.7, "protein": 0.1, "fat": 0, "fiber": 0.1},
        {"name": "Rice Vinegar", "amount": "10ml", "calories": 3, "carbs": 0.5, "protein": 0, "fat": 0, "fiber": 0}
    ],
    "ramen": [
        {"name": "Ramen Noodles", "amount": "180g", "calories": 210, "carbs": 42, "protein": 6, "fat": 1.5, "fiber": 1.5},
        {"name": "Pork Broth", "amount": "300ml", "calories": 90, "carbs": 2, "protein": 6, "fat": 6, "fiber": 0},
        {"name": "Chashu Pork", "amount": "60g", "calories": 100, "carbs": 2, "protein": 8, "fat": 7, "fiber": 0},
        {"name": "Soft-Boiled Egg", "amount": "50g", "calories": 72, "carbs": 0.4, "protein": 6.3, "fat": 5, "fiber": 0},
        {"name": "Green Onion", "amount": "10g", "calories": 3, "carbs": 0.7, "protein": 0.2, "fat": 0, "fiber": 0.3},
        {"name": "Nori", "amount": "3g", "calories": 1, "carbs": 0.2, "protein": 0.2, "fat": 0, "fiber": 0.1}
    ],
    "bibimbap": [
        {"name": "Steamed Rice", "amount": "200g", "calories": 260, "carbs": 56, "protein": 4.8, "fat": 0.6, "fiber": 0.6},
        {"name": "Ground Beef", "amount": "60g", "calories": 100, "carbs": 0, "protein": 10, "fat": 7, "fiber": 0},
        {"name": "Egg", "amount": "50g", "calories": 72, "carbs": 0.4, "protein": 6.3, "fat": 5, "fiber": 0},
        {"name": "Spinach", "amount": "40g", "calories": 9, "carbs": 1.4, "protein": 1.1, "fat": 0.2, "fiber": 0.9},
        {"name": "Carrot", "amount": "30g", "calories": 12, "carbs": 2.9, "protein": 0.3, "fat": 0.1, "fiber": 0.8},
        {"name": "Zucchini", "amount": "30g", "calories": 5, "carbs": 1, "protein": 0.4, "fat": 0.1, "fiber": 0.3},
        {"name": "Gochujang Sauce", "amount": "15g", "calories": 20, "carbs": 4, "protein": 0.5, "fat": 0.3, "fiber": 0.5},
        {"name": "Sesame Oil", "amount": "5ml", "calories": 44, "carbs": 0, "protein": 0, "fat": 5, "fiber": 0}
    ],
    "pho": [
        {"name": "Rice Noodles", "amount": "180g", "calories": 165, "carbs": 36, "protein": 2.5, "fat": 0.4, "fiber": 0.5},
        {"name": "Beef Broth", "amount": "350ml", "calories": 55, "carbs": 1, "protein": 6, "fat": 3, "fiber": 0},
        {"name": "Beef Slices", "amount": "80g", "calories": 100, "carbs": 0, "protein": 16, "fat": 4, "fiber": 0},
        {"name": "Bean Sprouts", "amount": "40g", "calories": 12, "carbs": 2.4, "protein": 1.2, "fat": 0.1, "fiber": 0.7},
        {"name": "Thai Basil", "amount": "5g", "calories": 1, "carbs": 0.2, "protein": 0.1, "fat": 0, "fiber": 0.1},
        {"name": "Lime", "amount": "15g", "calories": 4, "carbs": 1.4, "protein": 0.1, "fat": 0, "fiber": 0.2}
    ],
    "paella": [
        {"name": "Arborio Rice", "amount": "100g", "calories": 170, "carbs": 37, "protein": 3.5, "fat": 0.3, "fiber": 0.5},
        {"name": "Shrimp", "amount": "60g", "calories": 60, "carbs": 0, "protein": 12, "fat": 1, "fiber": 0},
        {"name": "Chicken Thigh", "amount": "50g", "calories": 65, "carbs": 0, "protein": 7, "fat": 4, "fiber": 0},
        {"name": "Chorizo", "amount": "20g", "calories": 52, "carbs": 0.5, "protein": 3, "fat": 4.5, "fiber": 0},
        {"name": "Bell Pepper", "amount": "30g", "calories": 9, "carbs": 2, "protein": 0.3, "fat": 0.1, "fiber": 0.6},
        {"name": "Peas", "amount": "25g", "calories": 21, "carbs": 3.8, "protein": 1.4, "fat": 0.1, "fiber": 1.5},
        {"name": "Saffron", "amount": "0.2g", "calories": 1, "carbs": 0.1, "protein": 0, "fat": 0, "fiber": 0},
        {"name": "Olive Oil", "amount": "10ml", "calories": 88, "carbs": 0, "protein": 0, "fat": 10, "fiber": 0}
    ],
    "lasagna": [
        {"name": "Lasagna Sheets", "amount": "80g", "calories": 140, "carbs": 28, "protein": 5, "fat": 1, "fiber": 1},
        {"name": "Ground Beef", "amount": "80g", "calories": 130, "carbs": 0, "protein": 12, "fat": 9, "fiber": 0},
        {"name": "Ricotta Cheese", "amount": "50g", "calories": 70, "carbs": 1.5, "protein": 5, "fat": 5, "fiber": 0},
        {"name": "Mozzarella", "amount": "40g", "calories": 80, "carbs": 0.5, "protein": 6, "fat": 6, "fiber": 0},
        {"name": "Tomato Sauce", "amount": "80g", "calories": 24, "carbs": 5, "protein": 1, "fat": 0.2, "fiber": 1},
        {"name": "Parmesan", "amount": "10g", "calories": 42, "carbs": 0.4, "protein": 3.6, "fat": 2.8, "fiber": 0}
    ],
    "spaghetti_bolognese": [
        {"name": "Spaghetti", "amount": "120g", "calories": 180, "carbs": 36, "protein": 6, "fat": 1, "fiber": 1.5},
        {"name": "Ground Beef", "amount": "80g", "calories": 130, "carbs": 0, "protein": 12, "fat": 9, "fiber": 0},
        {"name": "Tomato Sauce", "amount": "100g", "calories": 30, "carbs": 6.5, "protein": 1.2, "fat": 0.2, "fiber": 1.5},
        {"name": "Onion", "amount": "30g", "calories": 12, "carbs": 2.8, "protein": 0.3, "fat": 0, "fiber": 0.4},
        {"name": "Carrot", "amount": "20g", "calories": 8, "carbs": 1.9, "protein": 0.2, "fat": 0, "fiber": 0.6},
        {"name": "Olive Oil", "amount": "10ml", "calories": 88, "carbs": 0, "protein": 0, "fat": 10, "fiber": 0},
        {"name": "Parmesan", "amount": "10g", "calories": 42, "carbs": 0.4, "protein": 3.6, "fat": 2.8, "fiber": 0}
    ],
    "spaghetti_carbonara": [
        {"name": "Spaghetti", "amount": "120g", "calories": 180, "carbs": 36, "protein": 6, "fat": 1, "fiber": 1.5},
        {"name": "Pancetta", "amount": "40g", "calories": 130, "carbs": 0, "protein": 5, "fat": 12, "fiber": 0},
        {"name": "Egg Yolks", "amount": "40g", "calories": 110, "carbs": 1, "protein": 5.4, "fat": 9, "fiber": 0},
        {"name": "Pecorino Romano", "amount": "20g", "calories": 75, "carbs": 0.5, "protein": 5, "fat": 6, "fiber": 0},
        {"name": "Black Pepper", "amount": "2g", "calories": 5, "carbs": 1.3, "protein": 0.2, "fat": 0.1, "fiber": 0.5}
    ],
    "fried_rice": [
        {"name": "Cooked Rice", "amount": "200g", "calories": 260, "carbs": 56, "protein": 4.8, "fat": 0.6, "fiber": 0.6},
        {"name": "Egg", "amount": "50g", "calories": 72, "carbs": 0.4, "protein": 6.3, "fat": 5, "fiber": 0},
        {"name": "Peas & Carrots", "amount": "40g", "calories": 18, "carbs": 3.5, "protein": 0.8, "fat": 0.1, "fiber": 1.2},
        {"name": "Soy Sauce", "amount": "15ml", "calories": 8, "carbs": 1, "protein": 1.3, "fat": 0, "fiber": 0},
        {"name": "Green Onion", "amount": "10g", "calories": 3, "carbs": 0.7, "protein": 0.2, "fat": 0, "fiber": 0.3},
        {"name": "Sesame Oil", "amount": "10ml", "calories": 88, "carbs": 0, "protein": 0, "fat": 10, "fiber": 0}
    ],
    "eggs_benedict": [
        {"name": "English Muffin", "amount": "60g", "calories": 130, "carbs": 25, "protein": 5, "fat": 1, "fiber": 1},
        {"name": "Poached Eggs", "amount": "100g", "calories": 143, "carbs": 0.7, "protein": 12.6, "fat": 10, "fiber": 0},
        {"name": "Canadian Bacon", "amount": "40g", "calories": 56, "carbs": 0.5, "protein": 8, "fat": 2.5, "fiber": 0},
        {"name": "Hollandaise Sauce", "amount": "40g", "calories": 140, "carbs": 0.3, "protein": 1, "fat": 15, "fiber": 0}
    ],
    "breakfast_burrito": [
        {"name": "Flour Tortilla", "amount": "60g", "calories": 180, "carbs": 30, "protein": 4.5, "fat": 5, "fiber": 1.5},
        {"name": "Scrambled Eggs", "amount": "75g", "calories": 110, "carbs": 1, "protein": 8, "fat": 8.5, "fiber": 0},
        {"name": "Cheese", "amount": "20g", "calories": 80, "carbs": 0.3, "protein": 5, "fat": 6.5, "fiber": 0},
        {"name": "Salsa", "amount": "30g", "calories": 12, "carbs": 2.5, "protein": 0.5, "fat": 0, "fiber": 0.5},
        {"name": "Black Beans", "amount": "30g", "calories": 40, "carbs": 7, "protein": 2.5, "fat": 0.2, "fiber": 2.5}
    ],
    "dumplings": [
        {"name": "Dumpling Wrapper", "amount": "90g", "calories": 155, "carbs": 32, "protein": 4, "fat": 0.5, "fiber": 0.9},
        {"name": "Ground Pork", "amount": "60g", "calories": 130, "carbs": 0, "protein": 9, "fat": 10, "fiber": 0},
        {"name": "Napa Cabbage", "amount": "40g", "calories": 5, "carbs": 1, "protein": 0.5, "fat": 0, "fiber": 0.4},
        {"name": "Ginger", "amount": "3g", "calories": 2, "carbs": 0.5, "protein": 0.1, "fat": 0, "fiber": 0.1},
        {"name": "Soy Sauce (dip)", "amount": "15ml", "calories": 8, "carbs": 1, "protein": 1.3, "fat": 0, "fiber": 0},
        {"name": "Sesame Oil", "amount": "5ml", "calories": 44, "carbs": 0, "protein": 0, "fat": 5, "fiber": 0}
    ],
    "huevos_rancheros": [
        {"name": "Corn Tortilla", "amount": "50g", "calories": 105, "carbs": 22, "protein": 2.7, "fat": 1.3, "fiber": 3},
        {"name": "Eggs", "amount": "100g", "calories": 143, "carbs": 0.7, "protein": 12.6, "fat": 10, "fiber": 0},
        {"name": "Ranchero Sauce", "amount": "80g", "calories": 30, "carbs": 6, "protein": 1, "fat": 0.5, "fiber": 1.5},
        {"name": "Black Beans", "amount": "50g", "calories": 65, "carbs": 12, "protein": 4.3, "fat": 0.3, "fiber": 4.3},
        {"name": "Cheese", "amount": "15g", "calories": 55, "carbs": 0.3, "protein": 3.5, "fat": 4.5, "fiber": 0},
        {"name": "Avocado", "amount": "30g", "calories": 48, "carbs": 2.6, "protein": 0.6, "fat": 4.4, "fiber": 2}
    ],
    "french_onion_soup": [
        {"name": "Onions", "amount": "200g", "calories": 80, "carbs": 18.8, "protein": 2.2, "fat": 0.2, "fiber": 3.4},
        {"name": "Beef Broth", "amount": "250ml", "calories": 40, "carbs": 1, "protein": 4, "fat": 2, "fiber": 0},
        {"name": "Gruyère Cheese", "amount": "30g", "calories": 115, "carbs": 0.1, "protein": 8.4, "fat": 9, "fiber": 0},
        {"name": "Baguette Slice", "amount": "30g", "calories": 80, "carbs": 15, "protein": 2.5, "fat": 0.5, "fiber": 0.7},
        {"name": "Butter", "amount": "10g", "calories": 72, "carbs": 0, "protein": 0.1, "fat": 8, "fiber": 0}
    ],
    "lobster_bisque": [
        {"name": "Lobster Meat", "amount": "60g", "calories": 50, "carbs": 0, "protein": 11, "fat": 0.5, "fiber": 0},
        {"name": "Heavy Cream", "amount": "60ml", "calories": 120, "carbs": 1, "protein": 0.8, "fat": 13, "fiber": 0},
        {"name": "Butter", "amount": "10g", "calories": 72, "carbs": 0, "protein": 0.1, "fat": 8, "fiber": 0},
        {"name": "Tomato Paste", "amount": "15g", "calories": 13, "carbs": 2.8, "protein": 0.7, "fat": 0.1, "fiber": 0.5},
        {"name": "Sherry", "amount": "15ml", "calories": 20, "carbs": 1.5, "protein": 0, "fat": 0, "fiber": 0},
        {"name": "Seafood Stock", "amount": "200ml", "calories": 20, "carbs": 1, "protein": 2, "fat": 0.5, "fiber": 0}
    ],
    "fish_and_chips": [
        {"name": "Cod Fillet", "amount": "150g", "calories": 140, "carbs": 0, "protein": 30, "fat": 1.2, "fiber": 0},
        {"name": "Beer Batter", "amount": "50g", "calories": 120, "carbs": 22, "protein": 3, "fat": 2, "fiber": 0.5},
        {"name": "Potato Chips", "amount": "150g", "calories": 270, "carbs": 36, "protein": 3.5, "fat": 12, "fiber": 3},
        {"name": "Frying Oil", "amount": "20ml", "calories": 176, "carbs": 0, "protein": 0, "fat": 20, "fiber": 0},
        {"name": "Tartar Sauce", "amount": "20g", "calories": 50, "carbs": 2, "protein": 0.1, "fat": 5, "fiber": 0}
    ]
}

for food_id, ingredients in ingredients_for_existing.items():
    if food_id in lookup:
        lookup[food_id]['ingredients'] = ingredients


new_indian_dishes = [
    {
        "id": "sambar",
        "food_name": "Sambar",
        "serving_size": "1 bowl (250ml)",
        "calories": 180,
        "carbs": {"name": "Carbohydrates", "amount": 25, "unit": "g", "daily_percent": 8},
        "protein": {"name": "Protein", "amount": 9, "unit": "g", "daily_percent": 18},
        "fat": {"name": "Fat", "amount": 5, "unit": "g", "daily_percent": 8},
        "fiber": {"name": "Fiber", "amount": 6, "unit": "g", "daily_percent": 24},
        "sugar": {"name": "Sugar", "amount": 4, "unit": "g", "daily_percent": 8},
        "sodium": {"name": "Sodium", "amount": 650, "unit": "mg", "daily_percent": 28},
        "cholesterol": {"name": "Cholesterol", "amount": 0, "unit": "mg", "daily_percent": 0},
        "vitamins": [
            {"name": "Vitamin C", "amount": 15, "unit": "%DV"},
            {"name": "Iron", "amount": 12, "unit": "%DV"},
            {"name": "Folate", "amount": 18, "unit": "%DV"},
            {"name": "Potassium", "amount": 10, "unit": "%DV"}
        ],
        "ingredients": [
            {"name": "Toor Dal", "amount": "50g", "calories": 170, "carbs": 29, "protein": 12, "fat": 1.5, "fiber": 7.5},
            {"name": "Mixed Vegetables", "amount": "80g", "calories": 30, "carbs": 6, "protein": 1.5, "fat": 0.2, "fiber": 2.5},
            {"name": "Tamarind Paste", "amount": "10g", "calories": 12, "carbs": 3, "protein": 0.1, "fat": 0, "fiber": 0.5},
            {"name": "Sambar Powder", "amount": "8g", "calories": 20, "carbs": 3, "protein": 0.8, "fat": 0.5, "fiber": 1.5},
            {"name": "Coconut Oil (Tadka)", "amount": "5ml", "calories": 44, "carbs": 0, "protein": 0, "fat": 5, "fiber": 0},
            {"name": "Mustard Seeds & Curry Leaves", "amount": "3g", "calories": 8, "carbs": 1, "protein": 0.3, "fat": 0.3, "fiber": 0.5}
        ],
        "health_tip": "Rich in protein from lentils and fiber from vegetables. A South Indian staple packed with anti-inflammatory turmeric."
    },
    {
        "id": "rasam",
        "food_name": "Rasam",
        "serving_size": "1 bowl (250ml)",
        "calories": 90,
        "carbs": {"name": "Carbohydrates", "amount": 12, "unit": "g", "daily_percent": 4},
        "protein": {"name": "Protein", "amount": 4, "unit": "g", "daily_percent": 8},
        "fat": {"name": "Fat", "amount": 3, "unit": "g", "daily_percent": 5},
        "fiber": {"name": "Fiber", "amount": 2.5, "unit": "g", "daily_percent": 10},
        "sugar": {"name": "Sugar", "amount": 3, "unit": "g", "daily_percent": 6},
        "sodium": {"name": "Sodium", "amount": 580, "unit": "mg", "daily_percent": 25},
        "cholesterol": {"name": "Cholesterol", "amount": 0, "unit": "mg", "daily_percent": 0},
        "vitamins": [
            {"name": "Vitamin C", "amount": 20, "unit": "%DV"},
            {"name": "Iron", "amount": 8, "unit": "%DV"},
            {"name": "Vitamin A", "amount": 10, "unit": "%DV"},
            {"name": "Manganese", "amount": 6, "unit": "%DV"}
        ],
        "ingredients": [
            {"name": "Toor Dal", "amount": "25g", "calories": 85, "carbs": 14.5, "protein": 6, "fat": 0.8, "fiber": 3.8},
            {"name": "Tomato", "amount": "80g", "calories": 14, "carbs": 3.2, "protein": 0.7, "fat": 0.2, "fiber": 1},
            {"name": "Tamarind", "amount": "10g", "calories": 12, "carbs": 3, "protein": 0.1, "fat": 0, "fiber": 0.5},
            {"name": "Rasam Powder", "amount": "5g", "calories": 14, "carbs": 2, "protein": 0.5, "fat": 0.4, "fiber": 1},
            {"name": "Ghee (Tadka)", "amount": "5ml", "calories": 45, "carbs": 0, "protein": 0, "fat": 5, "fiber": 0},
            {"name": "Black Pepper & Cumin", "amount": "3g", "calories": 8, "carbs": 1.5, "protein": 0.3, "fat": 0.2, "fiber": 0.5}
        ],
        "health_tip": "Light and comforting digestive soup. Black pepper and cumin aid digestion and boost immunity."
    },
    {
        "id": "dal_tadka",
        "food_name": "Dal Tadka",
        "serving_size": "1 bowl (200g)",
        "calories": 220,
        "carbs": {"name": "Carbohydrates", "amount": 28, "unit": "g", "daily_percent": 9},
        "protein": {"name": "Protein", "amount": 12, "unit": "g", "daily_percent": 24},
        "fat": {"name": "Fat", "amount": 7, "unit": "g", "daily_percent": 11},
        "fiber": {"name": "Fiber", "amount": 5, "unit": "g", "daily_percent": 20},
        "sugar": {"name": "Sugar", "amount": 3, "unit": "g", "daily_percent": 6},
        "sodium": {"name": "Sodium", "amount": 550, "unit": "mg", "daily_percent": 24},
        "cholesterol": {"name": "Cholesterol", "amount": 0, "unit": "mg", "daily_percent": 0},
        "vitamins": [
            {"name": "Iron", "amount": 15, "unit": "%DV"},
            {"name": "Folate", "amount": 22, "unit": "%DV"},
            {"name": "Vitamin A", "amount": 8, "unit": "%DV"},
            {"name": "Magnesium", "amount": 10, "unit": "%DV"}
        ],
        "ingredients": [
            {"name": "Yellow Lentils (Toor Dal)", "amount": "60g", "calories": 204, "carbs": 35, "protein": 14, "fat": 1.8, "fiber": 9},
            {"name": "Onion", "amount": "30g", "calories": 12, "carbs": 2.8, "protein": 0.3, "fat": 0, "fiber": 0.4},
            {"name": "Tomato", "amount": "40g", "calories": 7, "carbs": 1.6, "protein": 0.4, "fat": 0.1, "fiber": 0.5},
            {"name": "Ghee (Tadka)", "amount": "8ml", "calories": 72, "carbs": 0, "protein": 0, "fat": 8, "fiber": 0},
            {"name": "Garlic & Cumin Seeds", "amount": "5g", "calories": 12, "carbs": 2, "protein": 0.5, "fat": 0.3, "fiber": 0.4},
            {"name": "Turmeric & Red Chili", "amount": "3g", "calories": 9, "carbs": 1.5, "protein": 0.3, "fat": 0.2, "fiber": 0.5}
        ],
        "health_tip": "Excellent plant-based protein source. The ghee tadka adds flavor and helps absorb fat-soluble vitamins from turmeric."
    },
    {
        "id": "palak_paneer",
        "food_name": "Palak Paneer",
        "serving_size": "1 cup (200g)",
        "calories": 280,
        "carbs": {"name": "Carbohydrates", "amount": 10, "unit": "g", "daily_percent": 3},
        "protein": {"name": "Protein", "amount": 16, "unit": "g", "daily_percent": 32},
        "fat": {"name": "Fat", "amount": 20, "unit": "g", "daily_percent": 31},
        "fiber": {"name": "Fiber", "amount": 4, "unit": "g", "daily_percent": 16},
        "sugar": {"name": "Sugar", "amount": 3, "unit": "g", "daily_percent": 6},
        "sodium": {"name": "Sodium", "amount": 480, "unit": "mg", "daily_percent": 21},
        "cholesterol": {"name": "Cholesterol", "amount": 40, "unit": "mg", "daily_percent": 13},
        "vitamins": [
            {"name": "Vitamin A", "amount": 120, "unit": "%DV"},
            {"name": "Vitamin K", "amount": 200, "unit": "%DV"},
            {"name": "Iron", "amount": 18, "unit": "%DV"},
            {"name": "Calcium", "amount": 25, "unit": "%DV"}
        ],
        "ingredients": [
            {"name": "Spinach (Palak)", "amount": "150g", "calories": 35, "carbs": 5.4, "protein": 4.3, "fat": 0.6, "fiber": 3.3},
            {"name": "Paneer", "amount": "75g", "calories": 195, "carbs": 1.5, "protein": 14, "fat": 15, "fiber": 0},
            {"name": "Onion", "amount": "30g", "calories": 12, "carbs": 2.8, "protein": 0.3, "fat": 0, "fiber": 0.4},
            {"name": "Cream", "amount": "15ml", "calories": 50, "carbs": 0.5, "protein": 0.4, "fat": 5.4, "fiber": 0},
            {"name": "Cooking Oil", "amount": "5ml", "calories": 44, "carbs": 0, "protein": 0, "fat": 5, "fiber": 0},
            {"name": "Ginger-Garlic & Spices", "amount": "5g", "calories": 12, "carbs": 2, "protein": 0.4, "fat": 0.3, "fiber": 0.3}
        ],
        "health_tip": "Exceptional source of vitamins A and K from spinach. Paneer adds protein and calcium."
    },
    {
        "id": "chole",
        "food_name": "Chole (Chickpea Curry)",
        "serving_size": "1 cup (200g)",
        "calories": 260,
        "carbs": {"name": "Carbohydrates", "amount": 35, "unit": "g", "daily_percent": 12},
        "protein": {"name": "Protein", "amount": 12, "unit": "g", "daily_percent": 24},
        "fat": {"name": "Fat", "amount": 9, "unit": "g", "daily_percent": 14},
        "fiber": {"name": "Fiber", "amount": 10, "unit": "g", "daily_percent": 40},
        "sugar": {"name": "Sugar", "amount": 5, "unit": "g", "daily_percent": 10},
        "sodium": {"name": "Sodium", "amount": 620, "unit": "mg", "daily_percent": 27},
        "cholesterol": {"name": "Cholesterol", "amount": 0, "unit": "mg", "daily_percent": 0},
        "vitamins": [
            {"name": "Iron", "amount": 20, "unit": "%DV"},
            {"name": "Folate", "amount": 35, "unit": "%DV"},
            {"name": "Manganese", "amount": 40, "unit": "%DV"},
            {"name": "Vitamin B6", "amount": 12, "unit": "%DV"}
        ],
        "ingredients": [
            {"name": "Chickpeas (Kabuli Chana)", "amount": "100g", "calories": 164, "carbs": 27, "protein": 9, "fat": 2.6, "fiber": 7.6},
            {"name": "Onion", "amount": "40g", "calories": 16, "carbs": 3.8, "protein": 0.4, "fat": 0, "fiber": 0.5},
            {"name": "Tomato", "amount": "50g", "calories": 9, "carbs": 2, "protein": 0.4, "fat": 0.1, "fiber": 0.6},
            {"name": "Cooking Oil", "amount": "10ml", "calories": 88, "carbs": 0, "protein": 0, "fat": 10, "fiber": 0},
            {"name": "Chole Masala", "amount": "8g", "calories": 22, "carbs": 3.5, "protein": 0.8, "fat": 0.6, "fiber": 1.5},
            {"name": "Ginger-Garlic Paste", "amount": "5g", "calories": 7, "carbs": 1.5, "protein": 0.2, "fat": 0, "fiber": 0.1}
        ],
        "health_tip": "Chickpeas are a fiber powerhouse. Excellent plant protein with very high folate and manganese content."
    },
    {
        "id": "aloo_gobi",
        "food_name": "Aloo Gobi",
        "serving_size": "1 cup (200g)",
        "calories": 190,
        "carbs": {"name": "Carbohydrates", "amount": 22, "unit": "g", "daily_percent": 7},
        "protein": {"name": "Protein", "amount": 5, "unit": "g", "daily_percent": 10},
        "fat": {"name": "Fat", "amount": 9, "unit": "g", "daily_percent": 14},
        "fiber": {"name": "Fiber", "amount": 5, "unit": "g", "daily_percent": 20},
        "sugar": {"name": "Sugar", "amount": 4, "unit": "g", "daily_percent": 8},
        "sodium": {"name": "Sodium", "amount": 420, "unit": "mg", "daily_percent": 18},
        "cholesterol": {"name": "Cholesterol", "amount": 0, "unit": "mg", "daily_percent": 0},
        "vitamins": [
            {"name": "Vitamin C", "amount": 65, "unit": "%DV"},
            {"name": "Vitamin K", "amount": 15, "unit": "%DV"},
            {"name": "Vitamin B6", "amount": 18, "unit": "%DV"},
            {"name": "Folate", "amount": 12, "unit": "%DV"}
        ],
        "ingredients": [
            {"name": "Potato (Aloo)", "amount": "100g", "calories": 77, "carbs": 17, "protein": 2, "fat": 0.1, "fiber": 2.2},
            {"name": "Cauliflower (Gobi)", "amount": "100g", "calories": 25, "carbs": 5, "protein": 2, "fat": 0.3, "fiber": 2},
            {"name": "Onion", "amount": "30g", "calories": 12, "carbs": 2.8, "protein": 0.3, "fat": 0, "fiber": 0.4},
            {"name": "Tomato", "amount": "30g", "calories": 5, "carbs": 1.2, "protein": 0.3, "fat": 0.1, "fiber": 0.4},
            {"name": "Cooking Oil", "amount": "10ml", "calories": 88, "carbs": 0, "protein": 0, "fat": 10, "fiber": 0},
            {"name": "Turmeric & Cumin", "amount": "4g", "calories": 10, "carbs": 1.8, "protein": 0.3, "fat": 0.3, "fiber": 0.5}
        ],
        "health_tip": "Cauliflower is very rich in vitamin C. Turmeric adds powerful anti-inflammatory curcumin."
    },
    {
        "id": "biryani",
        "food_name": "Biryani",
        "serving_size": "1 plate (350g)",
        "calories": 490,
        "carbs": {"name": "Carbohydrates", "amount": 58, "unit": "g", "daily_percent": 19},
        "protein": {"name": "Protein", "amount": 22, "unit": "g", "daily_percent": 44},
        "fat": {"name": "Fat", "amount": 18, "unit": "g", "daily_percent": 28},
        "fiber": {"name": "Fiber", "amount": 3, "unit": "g", "daily_percent": 12},
        "sugar": {"name": "Sugar", "amount": 3, "unit": "g", "daily_percent": 6},
        "sodium": {"name": "Sodium", "amount": 820, "unit": "mg", "daily_percent": 36},
        "cholesterol": {"name": "Cholesterol", "amount": 65, "unit": "mg", "daily_percent": 22},
        "vitamins": [
            {"name": "Vitamin B6", "amount": 20, "unit": "%DV"},
            {"name": "Iron", "amount": 15, "unit": "%DV"},
            {"name": "Niacin", "amount": 18, "unit": "%DV"},
            {"name": "Zinc", "amount": 12, "unit": "%DV"}
        ],
        "ingredients": [
            {"name": "Basmati Rice", "amount": "150g", "calories": 195, "carbs": 43, "protein": 4, "fat": 0.4, "fiber": 0.6},
            {"name": "Chicken (bone-in)", "amount": "120g", "calories": 160, "carbs": 0, "protein": 18, "fat": 9, "fiber": 0},
            {"name": "Onion (fried)", "amount": "40g", "calories": 55, "carbs": 5, "protein": 0.5, "fat": 3.5, "fiber": 0.5},
            {"name": "Yogurt Marinade", "amount": "30g", "calories": 18, "carbs": 1.4, "protein": 1, "fat": 1, "fiber": 0},
            {"name": "Ghee", "amount": "10ml", "calories": 90, "carbs": 0, "protein": 0, "fat": 10, "fiber": 0},
            {"name": "Biryani Spices & Saffron", "amount": "5g", "calories": 12, "carbs": 2, "protein": 0.4, "fat": 0.3, "fiber": 0.5},
            {"name": "Mint & Coriander", "amount": "5g", "calories": 2, "carbs": 0.3, "protein": 0.2, "fat": 0, "fiber": 0.2}
        ],
        "health_tip": "A complete meal with protein and carbs. Saffron provides antioxidants. Watch portion sizes due to high calorie density."
    },
    {
        "id": "idli",
        "food_name": "Idli",
        "serving_size": "3 pieces (150g)",
        "calories": 195,
        "carbs": {"name": "Carbohydrates", "amount": 38, "unit": "g", "daily_percent": 13},
        "protein": {"name": "Protein", "amount": 6, "unit": "g", "daily_percent": 12},
        "fat": {"name": "Fat", "amount": 1.5, "unit": "g", "daily_percent": 2},
        "fiber": {"name": "Fiber", "amount": 2, "unit": "g", "daily_percent": 8},
        "sugar": {"name": "Sugar", "amount": 1, "unit": "g", "daily_percent": 2},
        "sodium": {"name": "Sodium", "amount": 320, "unit": "mg", "daily_percent": 14},
        "cholesterol": {"name": "Cholesterol", "amount": 0, "unit": "mg", "daily_percent": 0},
        "vitamins": [
            {"name": "Iron", "amount": 8, "unit": "%DV"},
            {"name": "Folate", "amount": 10, "unit": "%DV"},
            {"name": "Thiamin", "amount": 8, "unit": "%DV"},
            {"name": "Calcium", "amount": 4, "unit": "%DV"}
        ],
        "ingredients": [
            {"name": "Rice (Parboiled)", "amount": "90g", "calories": 130, "carbs": 28, "protein": 2.5, "fat": 0.3, "fiber": 0.5},
            {"name": "Urad Dal (Black Gram)", "amount": "30g", "calories": 100, "carbs": 17, "protein": 7, "fat": 0.5, "fiber": 4.5},
            {"name": "Fenugreek Seeds", "amount": "2g", "calories": 7, "carbs": 1.2, "protein": 0.5, "fat": 0.1, "fiber": 0.5},
            {"name": "Salt", "amount": "2g", "calories": 0, "carbs": 0, "protein": 0, "fat": 0, "fiber": 0}
        ],
        "health_tip": "Steamed and fat-free — one of the healthiest Indian breakfasts. Fermentation improves nutrient bioavailability."
    },
    {
        "id": "dosa",
        "food_name": "Dosa",
        "serving_size": "1 large (120g)",
        "calories": 210,
        "carbs": {"name": "Carbohydrates", "amount": 32, "unit": "g", "daily_percent": 11},
        "protein": {"name": "Protein", "amount": 5, "unit": "g", "daily_percent": 10},
        "fat": {"name": "Fat", "amount": 7, "unit": "g", "daily_percent": 11},
        "fiber": {"name": "Fiber", "amount": 2, "unit": "g", "daily_percent": 8},
        "sugar": {"name": "Sugar", "amount": 1, "unit": "g", "daily_percent": 2},
        "sodium": {"name": "Sodium", "amount": 280, "unit": "mg", "daily_percent": 12},
        "cholesterol": {"name": "Cholesterol", "amount": 0, "unit": "mg", "daily_percent": 0},
        "vitamins": [
            {"name": "Iron", "amount": 8, "unit": "%DV"},
            {"name": "Folate", "amount": 8, "unit": "%DV"},
            {"name": "Thiamin", "amount": 6, "unit": "%DV"},
            {"name": "Niacin", "amount": 5, "unit": "%DV"}
        ],
        "ingredients": [
            {"name": "Rice Batter", "amount": "80g", "calories": 115, "carbs": 25, "protein": 2, "fat": 0.3, "fiber": 0.4},
            {"name": "Urad Dal Batter", "amount": "25g", "calories": 83, "carbs": 14, "protein": 5.8, "fat": 0.4, "fiber": 3.7},
            {"name": "Cooking Oil", "amount": "7ml", "calories": 62, "carbs": 0, "protein": 0, "fat": 7, "fiber": 0},
            {"name": "Salt", "amount": "1g", "calories": 0, "carbs": 0, "protein": 0, "fat": 0, "fiber": 0}
        ],
        "health_tip": "Fermented batter aids digestion. Plain dosa is lower in calories; masala dosa adds potato filling."
    },
    {
        "id": "upma",
        "food_name": "Upma",
        "serving_size": "1 bowl (200g)",
        "calories": 230,
        "carbs": {"name": "Carbohydrates", "amount": 32, "unit": "g", "daily_percent": 11},
        "protein": {"name": "Protein", "amount": 6, "unit": "g", "daily_percent": 12},
        "fat": {"name": "Fat", "amount": 8, "unit": "g", "daily_percent": 12},
        "fiber": {"name": "Fiber", "amount": 3, "unit": "g", "daily_percent": 12},
        "sugar": {"name": "Sugar", "amount": 2, "unit": "g", "daily_percent": 4},
        "sodium": {"name": "Sodium", "amount": 380, "unit": "mg", "daily_percent": 17},
        "cholesterol": {"name": "Cholesterol", "amount": 0, "unit": "mg", "daily_percent": 0},
        "vitamins": [
            {"name": "Iron", "amount": 10, "unit": "%DV"},
            {"name": "Thiamin", "amount": 12, "unit": "%DV"},
            {"name": "Folate", "amount": 8, "unit": "%DV"},
            {"name": "Vitamin B6", "amount": 6, "unit": "%DV"}
        ],
        "ingredients": [
            {"name": "Semolina (Rava/Sooji)", "amount": "60g", "calories": 180, "carbs": 37, "protein": 6, "fat": 0.6, "fiber": 1.3},
            {"name": "Onion", "amount": "30g", "calories": 12, "carbs": 2.8, "protein": 0.3, "fat": 0, "fiber": 0.4},
            {"name": "Green Peas", "amount": "20g", "calories": 16, "carbs": 2.9, "protein": 1.1, "fat": 0.1, "fiber": 1},
            {"name": "Cashews", "amount": "5g", "calories": 28, "carbs": 1.5, "protein": 0.9, "fat": 2.2, "fiber": 0.2},
            {"name": "Cooking Oil", "amount": "8ml", "calories": 70, "carbs": 0, "protein": 0, "fat": 8, "fiber": 0},
            {"name": "Mustard Seeds & Curry Leaves", "amount": "3g", "calories": 8, "carbs": 1, "protein": 0.3, "fat": 0.3, "fiber": 0.3}
        ],
        "health_tip": "Semolina is a good source of iron and B vitamins. A warm, satisfying breakfast option."
    },
    {
        "id": "poha",
        "food_name": "Poha",
        "serving_size": "1 bowl (200g)",
        "calories": 210,
        "carbs": {"name": "Carbohydrates", "amount": 34, "unit": "g", "daily_percent": 11},
        "protein": {"name": "Protein", "amount": 5, "unit": "g", "daily_percent": 10},
        "fat": {"name": "Fat", "amount": 6, "unit": "g", "daily_percent": 9},
        "fiber": {"name": "Fiber", "amount": 2, "unit": "g", "daily_percent": 8},
        "sugar": {"name": "Sugar", "amount": 2, "unit": "g", "daily_percent": 4},
        "sodium": {"name": "Sodium", "amount": 350, "unit": "mg", "daily_percent": 15},
        "cholesterol": {"name": "Cholesterol", "amount": 0, "unit": "mg", "daily_percent": 0},
        "vitamins": [
            {"name": "Iron", "amount": 30, "unit": "%DV"},
            {"name": "Vitamin C", "amount": 10, "unit": "%DV"},
            {"name": "Thiamin", "amount": 8, "unit": "%DV"},
            {"name": "Folate", "amount": 6, "unit": "%DV"}
        ],
        "ingredients": [
            {"name": "Flattened Rice (Poha)", "amount": "60g", "calories": 140, "carbs": 32, "protein": 2, "fat": 0.4, "fiber": 0.7},
            {"name": "Potato", "amount": "40g", "calories": 31, "carbs": 7, "protein": 0.8, "fat": 0, "fiber": 0.9},
            {"name": "Onion", "amount": "25g", "calories": 10, "carbs": 2.4, "protein": 0.3, "fat": 0, "fiber": 0.3},
            {"name": "Peanuts", "amount": "10g", "calories": 57, "carbs": 1.6, "protein": 2.6, "fat": 4.9, "fiber": 0.9},
            {"name": "Cooking Oil", "amount": "5ml", "calories": 44, "carbs": 0, "protein": 0, "fat": 5, "fiber": 0},
            {"name": "Lemon Juice", "amount": "10ml", "calories": 2, "carbs": 0.7, "protein": 0, "fat": 0, "fiber": 0}
        ],
        "health_tip": "Flattened rice is iron-fortified, making poha very high in iron. Lemon juice's vitamin C boosts iron absorption."
    },
    {
        "id": "pongal",
        "food_name": "Pongal",
        "serving_size": "1 bowl (200g)",
        "calories": 250,
        "carbs": {"name": "Carbohydrates", "amount": 35, "unit": "g", "daily_percent": 12},
        "protein": {"name": "Protein", "amount": 8, "unit": "g", "daily_percent": 16},
        "fat": {"name": "Fat", "amount": 9, "unit": "g", "daily_percent": 14},
        "fiber": {"name": "Fiber", "amount": 2.5, "unit": "g", "daily_percent": 10},
        "sugar": {"name": "Sugar", "amount": 1, "unit": "g", "daily_percent": 2},
        "sodium": {"name": "Sodium", "amount": 400, "unit": "mg", "daily_percent": 17},
        "cholesterol": {"name": "Cholesterol", "amount": 10, "unit": "mg", "daily_percent": 3},
        "vitamins": [
            {"name": "Iron", "amount": 10, "unit": "%DV"},
            {"name": "Folate", "amount": 12, "unit": "%DV"},
            {"name": "Thiamin", "amount": 10, "unit": "%DV"},
            {"name": "Manganese", "amount": 8, "unit": "%DV"}
        ],
        "ingredients": [
            {"name": "Raw Rice", "amount": "60g", "calories": 130, "carbs": 28, "protein": 2.5, "fat": 0.3, "fiber": 0.4},
            {"name": "Moong Dal", "amount": "30g", "calories": 105, "carbs": 18, "protein": 7.5, "fat": 0.4, "fiber": 4.8},
            {"name": "Ghee", "amount": "8ml", "calories": 72, "carbs": 0, "protein": 0, "fat": 8, "fiber": 0},
            {"name": "Black Pepper", "amount": "2g", "calories": 5, "carbs": 1.3, "protein": 0.2, "fat": 0.1, "fiber": 0.5},
            {"name": "Cumin Seeds", "amount": "2g", "calories": 7, "carbs": 0.9, "protein": 0.4, "fat": 0.4, "fiber": 0.2},
            {"name": "Cashews", "amount": "5g", "calories": 28, "carbs": 1.5, "protein": 0.9, "fat": 2.2, "fiber": 0.2}
        ],
        "health_tip": "Rice and lentil combination provides complete protein. Ghee adds richness and helps digest pepper compounds."
    },
    {
        "id": "butter_chicken",
        "food_name": "Butter Chicken",
        "serving_size": "1 cup (250g)",
        "calories": 380,
        "carbs": {"name": "Carbohydrates", "amount": 12, "unit": "g", "daily_percent": 4},
        "protein": {"name": "Protein", "amount": 28, "unit": "g", "daily_percent": 56},
        "fat": {"name": "Fat", "amount": 24, "unit": "g", "daily_percent": 37},
        "fiber": {"name": "Fiber", "amount": 2, "unit": "g", "daily_percent": 8},
        "sugar": {"name": "Sugar", "amount": 6, "unit": "g", "daily_percent": 12},
        "sodium": {"name": "Sodium", "amount": 750, "unit": "mg", "daily_percent": 33},
        "cholesterol": {"name": "Cholesterol", "amount": 95, "unit": "mg", "daily_percent": 32},
        "vitamins": [
            {"name": "Vitamin A", "amount": 20, "unit": "%DV"},
            {"name": "Vitamin B6", "amount": 25, "unit": "%DV"},
            {"name": "Iron", "amount": 12, "unit": "%DV"},
            {"name": "Niacin", "amount": 30, "unit": "%DV"}
        ],
        "ingredients": [
            {"name": "Chicken Breast", "amount": "150g", "calories": 165, "carbs": 0, "protein": 31, "fat": 3.6, "fiber": 0},
            {"name": "Butter", "amount": "15g", "calories": 108, "carbs": 0, "protein": 0.1, "fat": 12, "fiber": 0},
            {"name": "Tomato Puree", "amount": "80g", "calories": 24, "carbs": 5, "protein": 1, "fat": 0.2, "fiber": 1.5},
            {"name": "Heavy Cream", "amount": "30ml", "calories": 100, "carbs": 0.8, "protein": 0.6, "fat": 10.8, "fiber": 0},
            {"name": "Yogurt Marinade", "amount": "20g", "calories": 12, "carbs": 0.9, "protein": 0.7, "fat": 0.7, "fiber": 0},
            {"name": "Kashmiri Chili & Spices", "amount": "5g", "calories": 15, "carbs": 2.5, "protein": 0.5, "fat": 0.5, "fiber": 1},
            {"name": "Ginger-Garlic Paste", "amount": "5g", "calories": 7, "carbs": 1.5, "protein": 0.2, "fat": 0, "fiber": 0.1}
        ],
        "health_tip": "High in protein from chicken. Rich and creamy — enjoy in moderation. Tomatoes provide lycopene."
    },
    {
        "id": "tandoori_chicken",
        "food_name": "Tandoori Chicken",
        "serving_size": "2 pieces (200g)",
        "calories": 260,
        "carbs": {"name": "Carbohydrates", "amount": 5, "unit": "g", "daily_percent": 2},
        "protein": {"name": "Protein", "amount": 32, "unit": "g", "daily_percent": 64},
        "fat": {"name": "Fat", "amount": 12, "unit": "g", "daily_percent": 18},
        "fiber": {"name": "Fiber", "amount": 0.5, "unit": "g", "daily_percent": 2},
        "sugar": {"name": "Sugar", "amount": 2, "unit": "g", "daily_percent": 4},
        "sodium": {"name": "Sodium", "amount": 680, "unit": "mg", "daily_percent": 30},
        "cholesterol": {"name": "Cholesterol", "amount": 110, "unit": "mg", "daily_percent": 37},
        "vitamins": [
            {"name": "Vitamin B6", "amount": 30, "unit": "%DV"},
            {"name": "Niacin", "amount": 40, "unit": "%DV"},
            {"name": "Selenium", "amount": 25, "unit": "%DV"},
            {"name": "Phosphorus", "amount": 20, "unit": "%DV"}
        ],
        "ingredients": [
            {"name": "Chicken Leg/Thigh", "amount": "180g", "calories": 230, "carbs": 0, "protein": 28, "fat": 12, "fiber": 0},
            {"name": "Yogurt Marinade", "amount": "30g", "calories": 18, "carbs": 1.4, "protein": 1, "fat": 1, "fiber": 0},
            {"name": "Tandoori Masala", "amount": "8g", "calories": 22, "carbs": 3.5, "protein": 0.8, "fat": 0.6, "fiber": 1.2},
            {"name": "Lemon Juice", "amount": "10ml", "calories": 2, "carbs": 0.7, "protein": 0, "fat": 0, "fiber": 0},
            {"name": "Cooking Oil", "amount": "3ml", "calories": 27, "carbs": 0, "protein": 0, "fat": 3, "fiber": 0}
        ],
        "health_tip": "One of the healthiest Indian non-veg options — high protein, no heavy gravy. Yogurt marinade tenderizes and adds probiotics."
    },
    {
        "id": "chapati",
        "food_name": "Chapati",
        "serving_size": "2 pieces (60g)",
        "calories": 180,
        "carbs": {"name": "Carbohydrates", "amount": 30, "unit": "g", "daily_percent": 10},
        "protein": {"name": "Protein", "amount": 6, "unit": "g", "daily_percent": 12},
        "fat": {"name": "Fat", "amount": 4, "unit": "g", "daily_percent": 6},
        "fiber": {"name": "Fiber", "amount": 4, "unit": "g", "daily_percent": 16},
        "sugar": {"name": "Sugar", "amount": 0.5, "unit": "g", "daily_percent": 1},
        "sodium": {"name": "Sodium", "amount": 240, "unit": "mg", "daily_percent": 10},
        "cholesterol": {"name": "Cholesterol", "amount": 0, "unit": "mg", "daily_percent": 0},
        "vitamins": [
            {"name": "Iron", "amount": 12, "unit": "%DV"},
            {"name": "Thiamin", "amount": 15, "unit": "%DV"},
            {"name": "Folate", "amount": 10, "unit": "%DV"},
            {"name": "Manganese", "amount": 20, "unit": "%DV"}
        ],
        "ingredients": [
            {"name": "Whole Wheat Flour (Atta)", "amount": "50g", "calories": 170, "carbs": 36, "protein": 6.5, "fat": 1.2, "fiber": 5.5},
            {"name": "Ghee (brushed)", "amount": "3ml", "calories": 27, "carbs": 0, "protein": 0, "fat": 3, "fiber": 0},
            {"name": "Salt", "amount": "1g", "calories": 0, "carbs": 0, "protein": 0, "fat": 0, "fiber": 0}
        ],
        "health_tip": "Whole wheat chapati is rich in fiber and complex carbs. A healthier bread alternative to naan."
    }
]


new_standalone = [
    {
        "id": "banana",
        "food_name": "Banana",
        "serving_size": "1 medium (118g)",
        "calories": 105,
        "carbs": {"name": "Carbohydrates", "amount": 27, "unit": "g", "daily_percent": 9},
        "protein": {"name": "Protein", "amount": 1.3, "unit": "g", "daily_percent": 3},
        "fat": {"name": "Fat", "amount": 0.4, "unit": "g", "daily_percent": 1},
        "fiber": {"name": "Fiber", "amount": 3.1, "unit": "g", "daily_percent": 12},
        "sugar": {"name": "Sugar", "amount": 14, "unit": "g", "daily_percent": 28},
        "sodium": {"name": "Sodium", "amount": 1, "unit": "mg", "daily_percent": 0},
        "cholesterol": {"name": "Cholesterol", "amount": 0, "unit": "mg", "daily_percent": 0},
        "vitamins": [
            {"name": "Vitamin B6", "amount": 25, "unit": "%DV"},
            {"name": "Vitamin C", "amount": 15, "unit": "%DV"},
            {"name": "Potassium", "amount": 12, "unit": "%DV"},
            {"name": "Manganese", "amount": 14, "unit": "%DV"}
        ],
        "health_tip": "Excellent source of potassium for heart health. Natural energy booster before workouts."
    },
    {
        "id": "apple",
        "food_name": "Apple",
        "serving_size": "1 medium (182g)",
        "calories": 95,
        "carbs": {"name": "Carbohydrates", "amount": 25, "unit": "g", "daily_percent": 8},
        "protein": {"name": "Protein", "amount": 0.5, "unit": "g", "daily_percent": 1},
        "fat": {"name": "Fat", "amount": 0.3, "unit": "g", "daily_percent": 0},
        "fiber": {"name": "Fiber", "amount": 4.4, "unit": "g", "daily_percent": 18},
        "sugar": {"name": "Sugar", "amount": 19, "unit": "g", "daily_percent": 38},
        "sodium": {"name": "Sodium", "amount": 2, "unit": "mg", "daily_percent": 0},
        "cholesterol": {"name": "Cholesterol", "amount": 0, "unit": "mg", "daily_percent": 0},
        "vitamins": [
            {"name": "Vitamin C", "amount": 14, "unit": "%DV"},
            {"name": "Potassium", "amount": 6, "unit": "%DV"},
            {"name": "Vitamin K", "amount": 5, "unit": "%DV"},
            {"name": "Vitamin A", "amount": 2, "unit": "%DV"}
        ],
        "health_tip": "High in fiber — especially with the skin on. Contains quercetin, a powerful antioxidant."
    },
    {
        "id": "cooked_rice",
        "food_name": "Cooked Rice",
        "serving_size": "1 cup (158g)",
        "calories": 206,
        "carbs": {"name": "Carbohydrates", "amount": 45, "unit": "g", "daily_percent": 15},
        "protein": {"name": "Protein", "amount": 4.3, "unit": "g", "daily_percent": 9},
        "fat": {"name": "Fat", "amount": 0.4, "unit": "g", "daily_percent": 1},
        "fiber": {"name": "Fiber", "amount": 0.6, "unit": "g", "daily_percent": 2},
        "sugar": {"name": "Sugar", "amount": 0.1, "unit": "g", "daily_percent": 0},
        "sodium": {"name": "Sodium", "amount": 1, "unit": "mg", "daily_percent": 0},
        "cholesterol": {"name": "Cholesterol", "amount": 0, "unit": "mg", "daily_percent": 0},
        "vitamins": [
            {"name": "Manganese", "amount": 37, "unit": "%DV"},
            {"name": "Selenium", "amount": 17, "unit": "%DV"},
            {"name": "Niacin", "amount": 12, "unit": "%DV"},
            {"name": "Thiamin", "amount": 17, "unit": "%DV"}
        ],
        "health_tip": "A staple carbohydrate worldwide. Choose brown rice for more fiber and nutrients."
    },
    {
        "id": "boiled_egg",
        "food_name": "Boiled Egg",
        "serving_size": "1 large (50g)",
        "calories": 78,
        "carbs": {"name": "Carbohydrates", "amount": 0.6, "unit": "g", "daily_percent": 0},
        "protein": {"name": "Protein", "amount": 6.3, "unit": "g", "daily_percent": 13},
        "fat": {"name": "Fat", "amount": 5.3, "unit": "g", "daily_percent": 8},
        "fiber": {"name": "Fiber", "amount": 0, "unit": "g", "daily_percent": 0},
        "sugar": {"name": "Sugar", "amount": 0.6, "unit": "g", "daily_percent": 1},
        "sodium": {"name": "Sodium", "amount": 62, "unit": "mg", "daily_percent": 3},
        "cholesterol": {"name": "Cholesterol", "amount": 186, "unit": "mg", "daily_percent": 62},
        "vitamins": [
            {"name": "Vitamin D", "amount": 11, "unit": "%DV"},
            {"name": "Vitamin B12", "amount": 19, "unit": "%DV"},
            {"name": "Selenium", "amount": 28, "unit": "%DV"},
            {"name": "Riboflavin", "amount": 15, "unit": "%DV"}
        ],
        "health_tip": "Complete protein with all essential amino acids. One of the few natural sources of vitamin D."
    },
    {
        "id": "milk",
        "food_name": "Milk",
        "serving_size": "1 cup (244ml)",
        "calories": 149,
        "carbs": {"name": "Carbohydrates", "amount": 12, "unit": "g", "daily_percent": 4},
        "protein": {"name": "Protein", "amount": 8, "unit": "g", "daily_percent": 16},
        "fat": {"name": "Fat", "amount": 8, "unit": "g", "daily_percent": 12},
        "fiber": {"name": "Fiber", "amount": 0, "unit": "g", "daily_percent": 0},
        "sugar": {"name": "Sugar", "amount": 12, "unit": "g", "daily_percent": 24},
        "sodium": {"name": "Sodium", "amount": 105, "unit": "mg", "daily_percent": 5},
        "cholesterol": {"name": "Cholesterol", "amount": 24, "unit": "mg", "daily_percent": 8},
        "vitamins": [
            {"name": "Calcium", "amount": 28, "unit": "%DV"},
            {"name": "Vitamin D", "amount": 24, "unit": "%DV"},
            {"name": "Riboflavin", "amount": 26, "unit": "%DV"},
            {"name": "Vitamin B12", "amount": 18, "unit": "%DV"}
        ],
        "health_tip": "Excellent source of calcium and vitamin D for bone health. Whole milk values shown."
    },
    {
        "id": "curd_yogurt",
        "food_name": "Curd / Yogurt",
        "serving_size": "1 cup (245g)",
        "calories": 149,
        "carbs": {"name": "Carbohydrates", "amount": 11.4, "unit": "g", "daily_percent": 4},
        "protein": {"name": "Protein", "amount": 8.5, "unit": "g", "daily_percent": 17},
        "fat": {"name": "Fat", "amount": 8, "unit": "g", "daily_percent": 12},
        "fiber": {"name": "Fiber", "amount": 0, "unit": "g", "daily_percent": 0},
        "sugar": {"name": "Sugar", "amount": 11.4, "unit": "g", "daily_percent": 23},
        "sodium": {"name": "Sodium", "amount": 113, "unit": "mg", "daily_percent": 5},
        "cholesterol": {"name": "Cholesterol", "amount": 32, "unit": "mg", "daily_percent": 11},
        "vitamins": [
            {"name": "Calcium", "amount": 30, "unit": "%DV"},
            {"name": "Riboflavin", "amount": 22, "unit": "%DV"},
            {"name": "Vitamin B12", "amount": 23, "unit": "%DV"},
            {"name": "Phosphorus", "amount": 23, "unit": "%DV"}
        ],
        "health_tip": "Rich in probiotics for gut health. Excellent source of calcium and B vitamins."
    },
    {
        "id": "paneer",
        "food_name": "Paneer",
        "serving_size": "100g",
        "calories": 265,
        "carbs": {"name": "Carbohydrates", "amount": 1.2, "unit": "g", "daily_percent": 0},
        "protein": {"name": "Protein", "amount": 18.3, "unit": "g", "daily_percent": 37},
        "fat": {"name": "Fat", "amount": 20.8, "unit": "g", "daily_percent": 32},
        "fiber": {"name": "Fiber", "amount": 0, "unit": "g", "daily_percent": 0},
        "sugar": {"name": "Sugar", "amount": 0.9, "unit": "g", "daily_percent": 2},
        "sodium": {"name": "Sodium", "amount": 18, "unit": "mg", "daily_percent": 1},
        "cholesterol": {"name": "Cholesterol", "amount": 51, "unit": "mg", "daily_percent": 17},
        "vitamins": [
            {"name": "Calcium", "amount": 48, "unit": "%DV"},
            {"name": "Phosphorus", "amount": 30, "unit": "%DV"},
            {"name": "Riboflavin", "amount": 18, "unit": "%DV"},
            {"name": "Vitamin A", "amount": 12, "unit": "%DV"}
        ],
        "health_tip": "Excellent vegetarian protein source. Very high in calcium for bone health."
    },
    {
        "id": "chicken_breast",
        "food_name": "Chicken Breast",
        "serving_size": "1 piece cooked (120g)",
        "calories": 165,
        "carbs": {"name": "Carbohydrates", "amount": 0, "unit": "g", "daily_percent": 0},
        "protein": {"name": "Protein", "amount": 31, "unit": "g", "daily_percent": 62},
        "fat": {"name": "Fat", "amount": 3.6, "unit": "g", "daily_percent": 6},
        "fiber": {"name": "Fiber", "amount": 0, "unit": "g", "daily_percent": 0},
        "sugar": {"name": "Sugar", "amount": 0, "unit": "g", "daily_percent": 0},
        "sodium": {"name": "Sodium", "amount": 74, "unit": "mg", "daily_percent": 3},
        "cholesterol": {"name": "Cholesterol", "amount": 85, "unit": "mg", "daily_percent": 28},
        "vitamins": [
            {"name": "Niacin", "amount": 59, "unit": "%DV"},
            {"name": "Vitamin B6", "amount": 30, "unit": "%DV"},
            {"name": "Selenium", "amount": 44, "unit": "%DV"},
            {"name": "Phosphorus", "amount": 20, "unit": "%DV"}
        ],
        "health_tip": "Lean protein powerhouse. Very low in fat when skinless. Great for muscle building."
    },
    {
        "id": "potato",
        "food_name": "Potato",
        "serving_size": "1 medium boiled (150g)",
        "calories": 130,
        "carbs": {"name": "Carbohydrates", "amount": 30, "unit": "g", "daily_percent": 10},
        "protein": {"name": "Protein", "amount": 3, "unit": "g", "daily_percent": 6},
        "fat": {"name": "Fat", "amount": 0.2, "unit": "g", "daily_percent": 0},
        "fiber": {"name": "Fiber", "amount": 3, "unit": "g", "daily_percent": 12},
        "sugar": {"name": "Sugar", "amount": 1.5, "unit": "g", "daily_percent": 3},
        "sodium": {"name": "Sodium", "amount": 10, "unit": "mg", "daily_percent": 0},
        "cholesterol": {"name": "Cholesterol", "amount": 0, "unit": "mg", "daily_percent": 0},
        "vitamins": [
            {"name": "Vitamin C", "amount": 28, "unit": "%DV"},
            {"name": "Vitamin B6", "amount": 27, "unit": "%DV"},
            {"name": "Potassium", "amount": 18, "unit": "%DV"},
            {"name": "Manganese", "amount": 11, "unit": "%DV"}
        ],
        "health_tip": "Naturally fat-free and rich in potassium and vitamin C. Keep the skin on for extra fiber."
    },
    {
        "id": "tomato",
        "food_name": "Tomato",
        "serving_size": "1 medium (123g)",
        "calories": 22,
        "carbs": {"name": "Carbohydrates", "amount": 4.8, "unit": "g", "daily_percent": 2},
        "protein": {"name": "Protein", "amount": 1.1, "unit": "g", "daily_percent": 2},
        "fat": {"name": "Fat", "amount": 0.2, "unit": "g", "daily_percent": 0},
        "fiber": {"name": "Fiber", "amount": 1.5, "unit": "g", "daily_percent": 6},
        "sugar": {"name": "Sugar", "amount": 3.2, "unit": "g", "daily_percent": 6},
        "sodium": {"name": "Sodium", "amount": 6, "unit": "mg", "daily_percent": 0},
        "cholesterol": {"name": "Cholesterol", "amount": 0, "unit": "mg", "daily_percent": 0},
        "vitamins": [
            {"name": "Vitamin C", "amount": 28, "unit": "%DV"},
            {"name": "Vitamin A", "amount": 17, "unit": "%DV"},
            {"name": "Vitamin K", "amount": 10, "unit": "%DV"},
            {"name": "Potassium", "amount": 7, "unit": "%DV"}
        ],
        "health_tip": "Rich in lycopene, a powerful antioxidant linked to reduced cancer risk. Cooking increases lycopene availability."
    },
    {
        "id": "onion",
        "food_name": "Onion",
        "serving_size": "1 medium (110g)",
        "calories": 44,
        "carbs": {"name": "Carbohydrates", "amount": 10.3, "unit": "g", "daily_percent": 3},
        "protein": {"name": "Protein", "amount": 1.2, "unit": "g", "daily_percent": 2},
        "fat": {"name": "Fat", "amount": 0.1, "unit": "g", "daily_percent": 0},
        "fiber": {"name": "Fiber", "amount": 1.9, "unit": "g", "daily_percent": 8},
        "sugar": {"name": "Sugar", "amount": 4.7, "unit": "g", "daily_percent": 9},
        "sodium": {"name": "Sodium", "amount": 4, "unit": "mg", "daily_percent": 0},
        "cholesterol": {"name": "Cholesterol", "amount": 0, "unit": "mg", "daily_percent": 0},
        "vitamins": [
            {"name": "Vitamin C", "amount": 12, "unit": "%DV"},
            {"name": "Vitamin B6", "amount": 7, "unit": "%DV"},
            {"name": "Folate", "amount": 5, "unit": "%DV"},
            {"name": "Manganese", "amount": 6, "unit": "%DV"}
        ],
        "health_tip": "Contains quercetin and sulfur compounds with anti-inflammatory and heart-protective benefits."
    }
]

for dish in new_indian_dishes:
    db.append(dish)

for item in new_standalone:
    db.append(item)

with open(r'C:\Users\HP\.gemini\antigravity\scratch\nutri_snap\assets\data\nutrition_db.json', 'w', encoding='utf-8') as f:
    json.dump(db, f, indent=2, ensure_ascii=False)

existing_ids = set()
for item in db:
    existing_ids.add(item['id'])

items_with_ingredients = sum(1 for item in db if 'ingredients' in item)
print(f"Total entries: {len(db)}")
print(f"Unique IDs: {len(existing_ids)}")
print(f"Items with ingredients: {items_with_ingredients}")
print("Done!")
