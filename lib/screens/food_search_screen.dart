import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/imagenet_food_mapper.dart';
import '../services/nutrition_db_service.dart';
import '../services/nutrition_lookup_service.dart';
import '../services/web_classifier_service.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class FoodSearchScreen extends StatefulWidget {
  final Uint8List? imageBytes;

  const FoodSearchScreen({super.key, this.imageBytes});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _searchController = TextEditingController();
  final _webClassifier = WebClassifierService();
  List<FoodEntry> _results = [];
  List<_SuggestedFood> _suggestions = [];
  bool _loading = true;
  bool _classifying = false;
  bool _hasSearched = false;
  String? _classifyStatus;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {

    await NutritionDbService.instance.load();

    setState(() {

      _results = widget.imageBytes != null
          ? []
          : NutritionDbService.instance.allFoods;
      _loading = false;
    });

    if (widget.imageBytes != null) {
      _classifyImage();
    }
  }

  Future<void> _classifyImage() async {
    if (widget.imageBytes == null) return;

    setState(() {
      _classifying = true;
      _classifyStatus = 'Loading AI model...';
    });

    if (kIsWeb) {

      final loaded = await _webClassifier.load();
      if (!loaded || !mounted) {
        setState(() {
          _classifying = false;
          _classifyStatus = null;
        });
        return;
      }

      setState(() => _classifyStatus = 'Analyzing image...');

      final predictions = await _webClassifier.classify(widget.imageBytes!);

      if (!mounted) return;

      if (predictions.isEmpty) {
        setState(() {
          _classifying = false;
          _classifyStatus = null;
        });
        return;
      }

      final mappedPredictions = predictions
          .map((p) => MapEntry(p.className, p.probability))
          .toList();
      final mapped = ImageNetFoodMapper.mapPredictions(mappedPredictions);

      final suggestions = <_SuggestedFood>[];
      for (final mp in mapped) {

        final food = NutritionDbService.instance.allFoods
            .where((f) => f.id == mp.foodId)
            .firstOrNull;
        if (food != null) {
          suggestions.add(_SuggestedFood(
            food: food,
            confidence: mp.confidence,
            aiLabel: mp.originalClass,
          ));
        }
      }

      if (suggestions.isNotEmpty && suggestions.first.confidence > 0.40) {
        _selectFood(suggestions.first.food);
        return;
      }

      setState(() {
        _suggestions = suggestions;
        _classifying = false;
        _classifyStatus = null;
      });
    } else {

      setState(() {
        _classifying = false;
        _classifyStatus = null;
      });
    }
  }

  void _onSearch(String query) {
    setState(() {
      _hasSearched = query.isNotEmpty;
      _results = query.isEmpty && widget.imageBytes != null
          ? []
          : NutritionDbService.instance.search(query);
    });
  }

  Future<void> _selectFood(FoodEntry food) async {

    setState(() => _classifying = true);

    try {
      final data = await NutritionLookupService.instance.lookup(food.name);

      if (!mounted) return;
      setState(() => _classifying = false);

      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find nutrition data for "${food.name}"'),
            backgroundColor: AppTheme.calorieOrange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, _) => ResultScreen(
            imageBytes: widget.imageBytes,
            nutritionData: data,
          ),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _classifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nutrition lookup error: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.imageBytes != null ? 'Identify Food' : 'Select Food',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 12),

              if (widget.imageBytes != null) ...[
                _buildImagePreview(),
                const SizedBox(height: 12),
              ],

              if (_classifying || _suggestions.isNotEmpty) ...[
                _buildSuggestionsSection(),
                const SizedBox(height: 12),
              ],

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: _suggestions.isNotEmpty
                        ? 'Not right? Search here...'
                        : 'Search food...',
                    hintStyle: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppTheme.primary.withValues(alpha: 0.7),
                    ),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.buttonRadius,
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppTheme.buttonRadius,
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppTheme.buttonRadius,
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

              const SizedBox(height: 8),

              if (_results.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _loading
                          ? 'Loading...'
                          : '${_results.length} foods found',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _hasSearched
                                        ? Icons.search_off_rounded
                                        : Icons.search_rounded,
                                    size: 48,
                                    color: _hasSearched
                                        ? AppTheme.textSecondary.withValues(alpha: 0.4)
                                        : AppTheme.primary.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _hasSearched
                                        ? 'No foods found'
                                        : widget.imageBytes != null
                                            ? 'Can\'t find your food?'
                                            : 'Search for a food item',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _hasSearched
                                        ? 'Try a different search term'
                                        : 'Type in the search bar above to find\nyour food and get nutrition details',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                          height: 1.5,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final food = _results[index];
                              return _FoodListTile(
                                food: food,
                                onTap: () => _selectFood(food),
                              )
                                  .animate()
                                  .fadeIn(
                                    delay: Duration(
                                      milliseconds:
                                          (50 * index).clamp(0, 500),
                                    ),
                                    duration: 300.ms,
                                  )
                                  .slideX(begin: 0.05);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: AppTheme.cardRadius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(widget.imageBytes!, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppTheme.background.withValues(alpha: 0.85),
                    AppTheme.background.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        _classifying
                            ? Icons.auto_awesome_rounded
                            : _suggestions.isNotEmpty
                                ? Icons.check_circle_rounded
                                : Icons.photo_rounded,
                        color: _suggestions.isNotEmpty
                            ? AppTheme.fiberGreen
                            : AppTheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _classifying
                              ? (_classifyStatus ?? 'Analyzing...')
                              : _suggestions.isNotEmpty
                                  ? 'Food identified!'
                                  : 'Photo captured',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _classifying
                        ? 'AI is working on it...'
                        : _suggestions.isNotEmpty
                            ? 'Tap a suggestion or search below'
                            : 'Search or browse to find your meal',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildSuggestionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'AI Suggestions',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (_classifying) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (_classifying)
            _buildLoadingChips()
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestions.map((s) {
                final percent = (s.confidence * 100).toStringAsFixed(0);
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _selectFood(s.food),
                    borderRadius: AppTheme.chipRadius,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withValues(alpha: 0.15),
                            AppTheme.accent.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: AppTheme.chipRadius,
                        border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restaurant_rounded,
                              size: 16, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            s.food.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$percent%',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildLoadingChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        3,
        (i) => Container(
          width: 110.0 + (i * 15),
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.5),
            borderRadius: AppTheme.chipRadius,
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
        )
            .animate(
                onPlay: (controller) => controller.repeat(reverse: true))
            .shimmer(
              duration: 1200.ms,
              color: AppTheme.primary.withValues(alpha: 0.15),
            ),
      ),
    );
  }
}

class _SuggestedFood {
  final FoodEntry food;
  final double confidence;
  final String aiLabel;

  const _SuggestedFood({
    required this.food,
    required this.confidence,
    required this.aiLabel,
  });
}

class _FoodListTile extends StatelessWidget {
  final FoodEntry food;
  final VoidCallback onTap;

  const _FoodListTile({required this.food, required this.onTap});

  IconData _foodIcon(String id) {
    if (id.contains('salad') || id.contains('edamame')) {
      return Icons.eco_rounded;
    }
    if (id.contains('soup') || id.contains('chowder') || id.contains('pho') ||
        id.contains('ramen') || id.contains('miso')) {
      return Icons.ramen_dining_rounded;
    }
    if (id.contains('cake') || id.contains('pie') || id.contains('mousse') ||
        id.contains('tiramisu') || id.contains('cheesecake') ||
        id.contains('cannoli') || id.contains('churros') ||
        id.contains('donut') || id.contains('waffle') ||
        id.contains('pancake') || id.contains('ice_cream') ||
        id.contains('macaron') || id.contains('panna_cotta') ||
        id.contains('creme_brulee') || id.contains('shortcake') ||
        id.contains('yogurt') || id.contains('beignet') ||
        id.contains('baklava') || id.contains('cupcake') ||
        id.contains('bread_pudding')) {
      return Icons.cake_rounded;
    }
    if (id.contains('sushi') || id.contains('sashimi') || id.contains('salmon') ||
        id.contains('fish') || id.contains('lobster') || id.contains('crab') ||
        id.contains('scallop') || id.contains('mussel') ||
        id.contains('oyster') || id.contains('shrimp') ||
        id.contains('calamari') || id.contains('ceviche') ||
        id.contains('tuna')) {
      return Icons.set_meal_rounded;
    }
    if (id.contains('pizza')) return Icons.local_pizza_rounded;
    if (id.contains('burger') || id.contains('hot_dog') ||
        id.contains('sandwich') || id.contains('club')) {
      return Icons.lunch_dining_rounded;
    }
    if (id.contains('fries') || id.contains('nachos') ||
        id.contains('onion_ring') || id.contains('garlic_bread')) {
      return Icons.fastfood_rounded;
    }
    return Icons.restaurant_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTheme.cardRadius,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.card.withValues(alpha: 0.3),
              borderRadius: AppTheme.cardRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _foodIcon(food.id),
                    size: 22,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        food.servingSize,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.calorieOrange.withValues(alpha: 0.1),
                    borderRadius: AppTheme.chipRadius,
                  ),
                  child: Text(
                    '${food.calories.toStringAsFixed(0)} cal',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.calorieOrange,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
