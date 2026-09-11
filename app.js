// NutriSnap (YOTRACKEZ) App Controller

// App State
const state = {
  dailyGoalCals: 2200,
  dailyGoalProtein: 140,
  dailyGoalCarbs: 250,
  dailyGoalFat: 70,
  dailyGoalWater: 2500,
  dailyGoalSteps: 10000,

  loggedMeals: [],
  waterIntake: 0,
  steps: 3450,
  xp: 0,
  level: 1,
  selectedFood: null,
  geminiKey: ''
};

// DOM Elements
const elements = {
  // Tabs
  tabs: document.querySelectorAll('.nav-tab'),
  panes: document.querySelectorAll('.tab-pane'),

  // Dropzone & Scan
  dropzone: document.getElementById('dropzone'),
  fileInput: document.getElementById('fileInput'),
  dropzoneContent: document.getElementById('dropzoneContent'),
  previewContainer: document.getElementById('previewContainer'),
  imagePreview: document.getElementById('imagePreview'),
  btnRemoveImage: document.getElementById('btnRemoveImage'),
  btnAnalyze: document.getElementById('btnAnalyze'),
  btnManualSearch: document.getElementById('btnManualSearch'),

  // Results
  resultPlaceholder: document.getElementById('resultPlaceholder'),
  resultContent: document.getElementById('resultContent'),
  resIcon: document.getElementById('resIcon'),
  resName: document.getElementById('resName'),
  resServing: document.getElementById('resServing'),
  resCals: document.getElementById('resCals'),
  resProtein: document.getElementById('resProtein'),
  resCarbs: document.getElementById('resCarbs'),
  resFat: document.getElementById('resFat'),
  resInsight: document.getElementById('resInsight'),
  btnLogMeal: document.getElementById('btnLogMeal'),

  // Dashboard
  dashCalCurrent: document.getElementById('dashCalCurrent'),
  dashCalPercent: document.getElementById('dashCalPercent'),
  dashCalRemaining: document.getElementById('dashCalRemaining'),
  calorieRingProgress: document.getElementById('calorieRingProgress'),
  dashProteinText: document.getElementById('dashProteinText'),
  dashCarbsText: document.getElementById('dashCarbsText'),
  dashFatText: document.getElementById('dashFatText'),
  barProtein: document.getElementById('barProtein'),
  barCarbs: document.getElementById('barCarbs'),
  barFat: document.getElementById('barFat'),
  waterCurrent: document.getElementById('waterCurrent'),
  barWater: document.getElementById('barWater'),
  btnAddWater250: document.getElementById('btnAddWater250'),
  btnAddWater500: document.getElementById('btnAddWater500'),
  btnResetWater: document.getElementById('btnResetWater'),
  stepCurrent: document.getElementById('stepCurrent'),
  barSteps: document.getElementById('barSteps'),
  btnAddSteps1000: document.getElementById('btnAddSteps1000'),
  btnAddSteps5000: document.getElementById('btnAddSteps5000'),

  // History
  historyList: document.getElementById('historyList'),
  btnClearHistory: document.getElementById('btnClearHistory'),

  // Avatar
  avatarName: document.getElementById('avatarName'),
  avatarTitle: document.getElementById('avatarTitle'),
  headerLevelText: document.getElementById('headerLevelText'),
  xpText: document.getElementById('xpText'),
  barXp: document.getElementById('barXp'),
  avatarQuote: document.getElementById('avatarQuote'),
  badgeHydrated: document.getElementById('badgeHydrated'),
  badgeMacroMaster: document.getElementById('badgeMacroMaster'),
  badgePedometer: document.getElementById('badgePedometer'),

  // Dock
  avatarDock: document.getElementById('avatarDock'),
  dockStatus: document.getElementById('dockStatus'),
  dockBtn: document.getElementById('dockBtn'),

  // Modals
  searchModal: document.getElementById('searchModal'),
  btnCloseSearchModal: document.getElementById('btnCloseSearchModal'),
  dbSearchInput: document.getElementById('dbSearchInput'),
  searchResultsList: document.getElementById('searchResultsList'),

  apiKeyModal: document.getElementById('apiKeyModal'),
  btnApiKey: document.getElementById('btnApiKey'),
  btnCloseKeyModal: document.getElementById('btnCloseKeyModal'),
  apiKeyInput: document.getElementById('apiKeyInput'),
  btnSaveKey: document.getElementById('btnSaveKey'),
  btnClearKey: document.getElementById('btnClearKey')
};

// Quotes for Avatar
const AVATAR_QUOTES = [
  "\"Great scan! Keeping your macros balanced optimizes cybernetic performance.\"",
  "\"Don't forget hydration! Drink water to keep your metabolism at max power.\"",
  "\"Log every meal to earn XP and level up your health defense stats!\"",
  "\"Consistency is key. Every healthy bite fuels your body's energy core.\""
];

// Initialize App
document.addEventListener('DOMContentLoaded', () => {
  loadLocalStorage();
  setupTabNavigation();
  setupScanDropzone();
  setupPresets();
  setupDashboardControls();
  setupSearchModal();
  setupApiKeyModal();
  renderAll();
});

// Local Storage
function loadLocalStorage() {
  const savedMeals = localStorage.getItem('nutri_meals');
  if (savedMeals) state.loggedMeals = JSON.parse(savedMeals);

  const savedWater = localStorage.getItem('nutri_water');
  if (savedWater) state.waterIntake = parseInt(savedWater, 10);

  const savedSteps = localStorage.getItem('nutri_steps');
  if (savedSteps) state.steps = parseInt(savedSteps, 10);

  const savedXp = localStorage.getItem('nutri_xp');
  if (savedXp) state.xp = parseInt(savedXp, 10);

  const savedKey = localStorage.getItem('nutri_gemini_key');
  if (savedKey) state.geminiKey = savedKey;

  calculateLevel();
}

function saveLocalStorage() {
  localStorage.setItem('nutri_meals', JSON.stringify(state.loggedMeals));
  localStorage.setItem('nutri_water', state.waterIntake.toString());
  localStorage.setItem('nutri_steps', state.steps.toString());
  localStorage.setItem('nutri_xp', state.xp.toString());
  if (state.geminiKey) localStorage.setItem('nutri_gemini_key', state.geminiKey);
}

// Tab Navigation
function setupTabNavigation() {
  elements.tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      elements.tabs.forEach(t => t.classList.remove('active'));
      elements.panes.forEach(p => p.classList.remove('active'));

      tab.classList.add('active');
      const targetId = tab.dataset.tab;
      document.getElementById(targetId).classList.add('active');
    });
  });

  elements.dockBtn.addEventListener('click', () => {
    // Switch to avatar tab
    elements.tabs[3].click();
  });
}

// Scan & Dropzone
function setupScanDropzone() {
  const dropzone = elements.dropzone;

  dropzone.addEventListener('dragover', (e) => {
    e.preventDefault();
    dropzone.style.borderColor = '#00F2FE';
  });

  dropzone.addEventListener('dragleave', () => {
    dropzone.style.borderColor = 'rgba(0, 242, 254, 0.35)';
  });

  dropzone.addEventListener('drop', (e) => {
    e.preventDefault();
    dropzone.style.borderColor = 'rgba(0, 242, 254, 0.35)';
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      handleImageFile(e.dataTransfer.files[0]);
    }
  });

  elements.fileInput.addEventListener('change', (e) => {
    if (e.target.files && e.target.files[0]) {
      handleImageFile(e.target.files[0]);
    }
  });

  elements.btnRemoveImage.addEventListener('click', (e) => {
    e.stopPropagation();
    resetPreview();
  });

  elements.btnAnalyze.addEventListener('click', () => {
    runAiAnalysis();
  });

  elements.btnLogMeal.addEventListener('click', () => {
    logSelectedMeal();
  });
}

function handleImageFile(file) {
  state.currentFileName = file.name;
  state.currentMimeType = file.type || 'image/jpeg';

  const reader = new FileReader();
  reader.onload = (e) => {
    state.currentImageBase64 = e.target.result;
    elements.imagePreview.src = e.target.result;
    elements.dropzoneContent.classList.add('hidden');
    elements.previewContainer.classList.remove('hidden');
    elements.btnAnalyze.disabled = false;

    // Simulate food match as default preview
    state.selectedFood = simulateAiFoodScan(file.name);
  };
  reader.readAsDataURL(file);
}

function resetPreview() {
  elements.fileInput.value = '';
  elements.imagePreview.src = '';
  elements.dropzoneContent.classList.remove('hidden');
  elements.previewContainer.classList.add('hidden');
  elements.btnAnalyze.disabled = true;
  state.selectedFood = null;
  state.currentImageBase64 = null;
  state.currentFileName = '';
}

// Presets
function setupPresets() {
  document.querySelectorAll('.preset-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      const sampleId = chip.dataset.sample;
      state.selectedFood = NUTRITION_DATABASE.find(x => x.id === sampleId);
      displayAnalysisResult(state.selectedFood);
    });
  });
}

async function runAiAnalysis() {
  elements.btnAnalyze.innerHTML = '<span class="icon">⏳</span> Analyzing with Online AI...';
  elements.btnAnalyze.disabled = true;

  try {
    if (state.geminiKey && state.currentImageBase64) {
      const onlineFood = await callGeminiVisionApi(state.geminiKey, state.currentImageBase64, state.currentMimeType);
      if (onlineFood) {
        state.selectedFood = onlineFood;
      }
    } else if (!state.geminiKey && state.currentImageBase64) {
      // Small notice that API Key enables live AI recognition
      elements.dockStatus.textContent = "💡 Add Gemini API Key for live AI photo vision!";
      setTimeout(() => { elements.dockStatus.textContent = "Ready to scan!"; }, 4000);
    }
  } catch (err) {
    console.warn("Online Gemini API call failed, using fallback database:", err);
  } finally {
    if (!state.selectedFood) {
      state.selectedFood = simulateAiFoodScan(state.currentFileName || '');
    }
    elements.btnAnalyze.innerHTML = '<span class="icon">⚡</span> Analyze Meal with AI';
    elements.btnAnalyze.disabled = false;
    displayAnalysisResult(state.selectedFood);
  }
}

async function callGeminiVisionApi(apiKey, base64Data, mimeType = 'image/jpeg') {
  const url = `https://nutrisnapproxy.vercel.app/api/analyze`;
  const cleanBase64 = base64Data.replace(/^data:image\/\w+;base64,/, '');

  const payload = {
    contents: [
      {
        parts: [
          { text: "You are a professional nutritionist AI. Analyze this meal photo carefully. Return ONLY a single valid raw JSON object (no markdown formatting, no backticks, no code blocks) with the following structure:\n{\n  \"name\": \"Food Name\",\n  \"icon\": \"Emoji\",\n  \"serving\": \"1 plate (350g)\",\n  \"calories\": 450,\n  \"protein\": 30,\n  \"carbs\": 40,\n  \"fat\": 15,\n  \"insight\": \"A quick 1-sentence nutritional advice.\"\n}" },
          {
            inline_data: {
              mime_type: mimeType,
              data: cleanBase64
            }
          }
        ]
      }
    ]
  };

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });

  if (!response.ok) {
    throw new Error(`Proxy API HTTP Error: ${response.status}`);
  }

  const data = await response.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text || '';
  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (jsonMatch) {
    return JSON.parse(jsonMatch[0]);
  }
  return null;
}

function displayAnalysisResult(foodItem) {
  if (!foodItem) return;

  elements.resultPlaceholder.classList.add('hidden');
  elements.resultContent.classList.remove('hidden');

  elements.resIcon.textContent = foodItem.icon;
  elements.resName.textContent = foodItem.name;
  elements.resServing.textContent = foodItem.serving;
  elements.resCals.textContent = foodItem.calories;
  elements.resProtein.textContent = `${foodItem.protein}g`;
  elements.resCarbs.textContent = `${foodItem.carbs}g`;
  elements.resFat.textContent = `${foodItem.fat}g`;

  // Insight generator
  if (foodItem.protein > 25) {
    elements.resInsight.textContent = "High Protein powerhouse! Perfect for muscle repair and satiety.";
  } else if (foodItem.calories > 500) {
    elements.resInsight.textContent = "Energy-dense meal. Enjoy and keep your evening light!";
  } else {
    elements.resInsight.textContent = "Balanced nutrient profile for steady fuel.";
  }
}

function logSelectedMeal() {
  if (!state.selectedFood) return;

  const newLog = {
    id: Date.now(),
    name: state.selectedFood.name,
    icon: state.selectedFood.icon,
    calories: state.selectedFood.calories,
    protein: state.selectedFood.protein,
    carbs: state.selectedFood.carbs,
    fat: state.selectedFood.fat,
    time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  };

  state.loggedMeals.unshift(newLog);
  state.xp += 50;
  calculateLevel();
  saveLocalStorage();
  renderAll();

  // Show dock toast message
  elements.dockStatus.textContent = `+50 XP! Logged ${newLog.name}`;
  setTimeout(() => {
    elements.dockStatus.textContent = "Ready to scan!";
  }, 3500);

  // Switch to Dashboard
  elements.tabs[1].click();
}

// Dashboard & State Controls
function setupDashboardControls() {
  elements.btnAddWater250.addEventListener('click', () => addWater(250));
  elements.btnAddWater500.addEventListener('click', () => addWater(500));
  elements.btnResetWater.addEventListener('click', () => {
    state.waterIntake = 0;
    saveLocalStorage();
    renderDashboard();
  });

  elements.btnAddSteps1000.addEventListener('click', () => addSteps(1000));
  elements.btnAddSteps5000.addEventListener('click', () => addSteps(5000));

  elements.btnClearHistory.addEventListener('click', () => {
    if (confirm("Clear all logged meals from history?")) {
      state.loggedMeals = [];
      saveLocalStorage();
      renderAll();
    }
  });
}

function addWater(amount) {
  state.waterIntake += amount;
  state.xp += 10;
  calculateLevel();
  saveLocalStorage();
  renderDashboard();
  renderAvatar();
}

function addSteps(amount) {
  state.steps += amount;
  state.xp += 20;
  calculateLevel();
  saveLocalStorage();
  renderDashboard();
  renderAvatar();
}

function calculateLevel() {
  state.level = Math.floor(state.xp / 200) + 1;
}

// Render Functions
function renderAll() {
  renderDashboard();
  renderHistory();
  renderAvatar();
}

function renderDashboard() {
  // Totals
  const totalCals = state.loggedMeals.reduce((acc, m) => acc + m.calories, 0);
  const totalProtein = state.loggedMeals.reduce((acc, m) => acc + m.protein, 0);
  const totalCarbs = state.loggedMeals.reduce((acc, m) => acc + m.carbs, 0);
  const totalFat = state.loggedMeals.reduce((acc, m) => acc + m.fat, 0);

  // Calorie Ring
  elements.dashCalCurrent.textContent = totalCals.toLocaleString();
  const pctCals = Math.min(100, Math.round((totalCals / state.dailyGoalCals) * 100));
  elements.dashCalPercent.textContent = `${pctCals}%`;

  const remaining = Math.max(0, state.dailyGoalCals - totalCals);
  elements.dashCalRemaining.textContent = `${remaining.toLocaleString()} kcal`;

  // Ring offset calculation (440 circumference)
  const offset = 440 - (440 * (pctCals / 100));
  elements.calorieRingProgress.style.strokeDashoffset = offset;

  // Macros
  elements.dashProteinText.textContent = `${totalProtein} / ${state.dailyGoalProtein}g`;
  elements.dashCarbsText.textContent = `${totalCarbs} / ${state.dailyGoalCarbs}g`;
  elements.dashFatText.textContent = `${totalFat} / ${state.dailyGoalFat}g`;

  elements.barProtein.style.width = `${Math.min(100, (totalProtein / state.dailyGoalProtein) * 100)}%`;
  elements.barCarbs.style.width = `${Math.min(100, (totalCarbs / state.dailyGoalCarbs) * 100)}%`;
  elements.barFat.style.width = `${Math.min(100, (totalFat / state.dailyGoalFat) * 100)}%`;

  // Water
  elements.waterCurrent.textContent = `${state.waterIntake.toLocaleString()} ml`;
  elements.barWater.style.width = `${Math.min(100, (state.waterIntake / state.dailyGoalWater) * 100)}%`;

  // Steps
  elements.stepCurrent.textContent = state.steps.toLocaleString();
  elements.barSteps.style.width = `${Math.min(100, (state.steps / state.dailyGoalSteps) * 100)}%`;
}

function renderHistory() {
  if (state.loggedMeals.length === 0) {
    elements.historyList.innerHTML = `
      <div class="result-placeholder" style="height:140px;">
        <p>No meals logged yet today. Go to Scan & AI tab to add your first meal!</p>
      </div>
    `;
    return;
  }

  elements.historyList.innerHTML = state.loggedMeals.map(m => `
    <div class="history-item">
      <div class="history-left">
        <span class="history-emoji">${m.icon}</span>
        <div>
          <span class="history-title">${m.name}</span>
          <span class="history-time">${m.time} • P:${m.protein}g C:${m.carbs}g F:${m.fat}g</span>
        </div>
      </div>
      <div class="history-right">
        <span class="history-cals">${m.calories} kcal</span>
      </div>
    </div>
  `).join('');
}

function renderAvatar() {
  elements.headerLevelText.textContent = `LVL ${state.level}`;
  elements.avatarTitle.textContent = `Level ${state.level} - Cyber Health Tracker`;

  const xpCurrent = state.xp % 200;
  elements.xpText.textContent = `${xpCurrent} / 200 XP`;
  elements.barXp.style.width = `${(xpCurrent / 200) * 100}%`;

  // Random quote
  const quoteIdx = state.level % AVATAR_QUOTES.length;
  elements.avatarQuote.textContent = AVATAR_QUOTES[quoteIdx];

  // Badges
  if (state.waterIntake >= 2000) {
    elements.badgeHydrated.classList.add('active');
  }
  if (state.loggedMeals.length >= 3) {
    elements.badgeMacroMaster.classList.add('active');
  }
  if (state.steps >= 10000) {
    elements.badgePedometer.classList.add('active');
  }
}

// Search Modal
function setupSearchModal() {
  elements.btnManualSearch.addEventListener('click', () => {
    elements.searchModal.classList.remove('hidden');
    renderSearchResults('');
  });

  elements.btnCloseSearchModal.addEventListener('click', () => {
    elements.searchModal.classList.add('hidden');
  });

  elements.dbSearchInput.addEventListener('input', (e) => {
    renderSearchResults(e.target.value);
  });
}

function renderSearchResults(query) {
  const results = searchNutritionDb(query);
  elements.searchResultsList.innerHTML = results.map(item => `
    <div class="search-item" data-id="${item.id}">
      <div>
        <strong>${item.icon} ${item.name}</strong>
        <div style="font-size:12px; color:#8E9BAE">${item.serving} • ${item.category}</div>
      </div>
      <div class="neon-orange" style="font-weight:bold">${item.calories} kcal</div>
    </div>
  `).join('');

  document.querySelectorAll('.search-item').forEach(el => {
    el.addEventListener('click', () => {
      const id = el.dataset.id;
      state.selectedFood = NUTRITION_DATABASE.find(x => x.id === id);
      elements.searchModal.classList.add('hidden');
      displayAnalysisResult(state.selectedFood);
    });
  });
}

// API Key Modal
function setupApiKeyModal() {
  elements.btnApiKey.addEventListener('click', () => {
    elements.apiKeyInput.value = state.geminiKey;
    elements.apiKeyModal.classList.remove('hidden');
  });

  elements.btnCloseKeyModal.addEventListener('click', () => {
    elements.apiKeyModal.classList.add('hidden');
  });

  elements.btnSaveKey.addEventListener('click', () => {
    state.geminiKey = elements.apiKeyInput.value.trim();
    saveLocalStorage();
    elements.apiKeyModal.classList.add('hidden');
    alert("Gemini API Key saved successfully!");
  });

  elements.btnClearKey.addEventListener('click', () => {
    state.geminiKey = '';
    elements.apiKeyInput.value = '';
    localStorage.removeItem('nutri_gemini_key');
    elements.apiKeyModal.classList.add('hidden');
  });
}
