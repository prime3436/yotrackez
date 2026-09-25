import json

with open(r'nutrition_db.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

ids = [d['id'] for d in data]
print(f"Total entries: {len(data)}")
print(f"Unique IDs: {len(set(ids))}")
print(f"Valid JSON: YES")

indian = ["sambar","rasam","dal_tadka","palak_paneer","chole","aloo_gobi","biryani","idli","dosa","upma","poha","pongal","butter_chicken","tandoori_chicken","chapati"]
standalone = ["banana","apple","cooked_rice","boiled_egg","milk","curd_yogurt","paneer","chicken_breast","potato","tomato","onion"]

print(f"\nAll 15 Indian dishes present: {all(x in ids for x in indian)}")
print(f"All 11 standalone ingredients present: {all(x in ids for x in standalone)}")

with_ingr = [d['id'] for d in data if 'ingredients' in d]
print(f"\nEntries with ingredients array ({len(with_ingr)}):")
for i in with_ingr:
    print(f"  - {i}")

for s in standalone:
    entry = next(d for d in data if d['id'] == s)
    if 'ingredients' in entry:
        print(f"ERROR: {s} should NOT have ingredients!")

old_entries = ["apple_pie","hamburger","pizza","steak","waffles"]
for oid in old_entries:
    if oid not in ids:
        print(f"ERROR: Missing old entry {oid}!")
    else:
        print(f"Old entry preserved: {oid}")
