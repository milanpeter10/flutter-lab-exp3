// ============================================================
// EXPERIMENT 3: Add Interactivity to App – Input and Forms
// App: Gadget Finder (product search & filter)
//
// CONCEPTS DEMONSTRATED
// 1. Search input      - TextFormField + TextEditingController
// 2. Category filter   - DropdownButtonFormField
// 3. Price filter      - Slider
// 4. Form validation   - Form + GlobalKey<FormState> + validator
// 5. setState          - rebuilds the list on every input change
// 6. ProductCard       - reusable StatelessWidget
// 7. Add to cart       - SnackBar + cart counter
// ============================================================

import 'package:flutter/material.dart';

void main() {
  runApp(const GadgetFinderApp());
}

// -------------------------------------------------------
// Palette – warm sand paper with terracotta and sage
// -------------------------------------------------------
const Color kPaper = Color(0xFFF6EFE6);
const Color kInk = Color(0xFF2B2A33);
const Color kTerracotta = Color(0xFF3D7EAA);
const Color kSage = Color(0xFFE07A5F);
const Color kCard = Color(0xFFFFFBF6);
const Color kMuted = Color(0xFF8A8478);

class GadgetFinderApp extends StatelessWidget {
  const GadgetFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gadget Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kPaper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kTerracotta,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2D8C9)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2D8C9)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kTerracotta, width: 1.6),
          ),
        ),
      ),
      home: const FinderPage(),
    );
  }
}

// -------------------------------------------------------
// Data model and catalogue (12 products)
// -------------------------------------------------------
class Product {
  final String name;
  final String category;
  final double price;
  final double rating;
  final IconData icon;
  final Color color;

  const Product({
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.icon,
    required this.color,
  });
}

const List<Product> catalogue = [
  Product(name: 'Laptop', category: 'Electronics', price: 75000, rating: 4.5, icon: Icons.laptop_mac, color: Color(0xFF3D5A80)),
  Product(name: 'Smartphone', category: 'Electronics', price: 55000, rating: 4.7, icon: Icons.smartphone, color: Color(0xFF7B5EA7)),
  Product(name: 'Headphones', category: 'Electronics', price: 8000, rating: 4.3, icon: Icons.headphones, color: Color(0xFF2A9D8F)),
  Product(name: 'Smart Watch', category: 'Electronics', price: 22000, rating: 4.4, icon: Icons.watch, color: Color(0xFFE76F51)),
  Product(name: 'Camera', category: 'Electronics', price: 45000, rating: 4.6, icon: Icons.camera_alt, color: Color(0xFFBC4749)),
  Product(name: 'Tablet', category: 'Electronics', price: 35000, rating: 4.2, icon: Icons.tablet_mac, color: Color(0xFF5B8E7D)),
  Product(name: 'Sneakers', category: 'Fashion', price: 4500, rating: 4.1, icon: Icons.directions_run, color: Color(0xFFF4A261)),
  Product(name: 'Backpack', category: 'Fashion', price: 2500, rating: 4.0, icon: Icons.backpack, color: Color(0xFF8D6E63)),
  Product(name: 'Sunglasses', category: 'Fashion', price: 1800, rating: 4.0, icon: Icons.wb_sunny, color: Color(0xFFE9C46A)),
  Product(name: 'Keyboard', category: 'Accessories', price: 3500, rating: 4.4, icon: Icons.keyboard, color: Color(0xFF4A5568)),
  Product(name: 'Mouse', category: 'Accessories', price: 1500, rating: 4.2, icon: Icons.mouse, color: Color(0xFF6C757D)),
  Product(name: 'USB Hub', category: 'Accessories', price: 2000, rating: 3.9, icon: Icons.usb, color: Color(0xFF588157)),
];

const List<String> categoryOptions = ['All', 'Electronics', 'Accessories', 'Fashion'];

String rupees(double v) {
  final s = v.round().toString();
  if (s.length <= 3) return '₹$s';
  final head = s.substring(0, s.length - 3).replaceAllMapped(
        RegExp(r'(\d)(?=(\d\d)+$)'),
        (m) => '${m[1]},',
      );
  return '₹$head,${s.substring(s.length - 3)}';
}

// -------------------------------------------------------
// Main page – owns all the state
// -------------------------------------------------------
class FinderPage extends StatefulWidget {
  const FinderPage({super.key});

  @override
  State<FinderPage> createState() => _FinderPageState();
}

class _FinderPageState extends State<FinderPage> {
  static const double _maxLimit = 100000;

  final _formKey = GlobalKey<FormState>();
  final _searchCtrl = TextEditingController();

  String _category = 'All';
  double _maxPrice = _maxLimit;
  int _cart = 0;

  // The list that is actually shown; recomputed inside setState
  List<Product> _shown = List.of(catalogue);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Combine search + category + price into one filter
  List<Product> _filter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    return catalogue.where((p) {
      final okName = q.isEmpty || p.name.toLowerCase().contains(q);
      final okCat = _category == 'All' || p.category == _category;
      final okPrice = p.price <= _maxPrice;
      return okName && okCat && okPrice;
    }).toList();
  }

  void _refresh() => setState(() => _shown = _filter());

  // Validator: empty is fine, otherwise letters/numbers/spaces, 2+ chars
  String? _validateSearch(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    if (v.length < 2) return 'Type at least 2 characters';
    if (!RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(v)) {
      return 'Only letters, numbers and spaces';
    }
    return null;
  }

  void _applyPressed() {
    // validate() runs every validator inside the Form
    if (_formKey.currentState!.validate()) {
      _refresh();
      _toast('Showing ${_shown.length} result${_shown.length == 1 ? '' : 's'}', kSage);
    }
  }

  void _reset() {
    _searchCtrl.clear();
    _category = 'All';
    _maxPrice = _maxLimit;
    _formKey.currentState?.reset();
    _refresh();
    _toast('Filters reset', kInk);
  }

  void _addToCart(Product p) {
    setState(() => _cart++);
    _toast('${p.name} added to cart', kTerracotta);
  }

  void _toast(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1400),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPaper,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Gadget Finder',
          style: TextStyle(
              fontWeight: FontWeight.w800, color: kInk, letterSpacing: -0.3),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Badge(
              label: Text('$_cart'),
              isLabelVisible: _cart > 0,
              backgroundColor: kTerracotta,
              child: const Icon(Icons.shopping_bag_outlined,
                  size: 28, color: kInk),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _filterPanel(),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${_shown.length} of ${catalogue.length} gadgets',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15, color: kInk),
              ),
              const Spacer(),
              Text('up to ${rupees(_maxPrice)}',
                  style: const TextStyle(color: kMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          if (_shown.isEmpty)
            _emptyState()
          else
            // shrinkWrap grid inside the page ListView
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _shown.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, i) => ProductCard(
                product: _shown[i],
                onAdd: () => _addToCart(_shown[i]),
              ),
            ),
        ],
      ),
    );
  }

  // -- Form: search, dropdown, slider, buttons --
  Widget _filterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9DFD0)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _searchCtrl,
              onChanged: (_) => _refresh(), // live filtering
              validator: _validateSearch,
              decoration: const InputDecoration(
                hintText: 'Search gadgets…',
                prefixIcon: Icon(Icons.search, color: kTerracotta),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined, color: kSage),
              ),
              items: categoryOptions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                _category = v;
                _refresh();
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('Max price',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: kTerracotta.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    rupees(_maxPrice),
                    style: const TextStyle(
                        color: kTerracotta, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            Slider(
              value: _maxPrice,
              min: 0,
              max: _maxLimit,
              divisions: 20,
              activeColor: kTerracotta,
              inactiveColor: const Color(0xFFEBDDCB),
              onChanged: (v) {
                _maxPrice = v;
                _refresh();
              },
            ),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _applyPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: kInk,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Apply'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kInk,
                      side: const BorderSide(color: kInk),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: const [
          Icon(Icons.search_off, size: 56, color: kMuted),
          SizedBox(height: 8),
          Text('Nothing matches those filters',
              style: TextStyle(color: kMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// -------------------------------------------------------
// Reusable ProductCard
// -------------------------------------------------------
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;

  const ProductCard({super.key, required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9DFD0)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 70,
            width: double.infinity,
            decoration: BoxDecoration(
              color: product.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(product.icon, size: 36, color: product.color),
          ),
          const SizedBox(height: 10),
          Text(product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 15, color: kInk)),
          Text(product.category,
              style: const TextStyle(fontSize: 11, color: kMuted)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(rupees(product.price),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: kTerracotta)),
              const Spacer(),
              const Icon(Icons.star_rounded, size: 15, color: Color(0xFFE9A23B)),
              Text('${product.rating}',
                  style: const TextStyle(fontSize: 11, color: kMuted)),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: kSage,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Add to cart',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
