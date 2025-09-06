// lib/ui/shop_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/purchase_provider.dart';
import 'app_scaffold.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const _accent = Color(0xFFCC5500);

  // Fake catalog (UI-only)
  final List<_ShopItem> _catalog = const [
    _ShopItem(
      id: 'ninja650',
      name: 'Ninja 650',
      maker: 'Kawasaki',
      priceINR: 199,
      thumbAsset: 'assets/shop/ninja650.png',
      tags: ['Sport', 'Twin'],
    ),
    _ShopItem(
      id: 'r1',
      name: 'YZF-R1',
      maker: 'Yamaha',
      priceINR: 249,
      thumbAsset: 'assets/shop/r1.png',
      tags: ['Superbike', 'Inline-4'],
    ),
    _ShopItem(
      id: 'panigale',
      name: 'Panigale V4',
      maker: 'Ducati',
      priceINR: 299,
      thumbAsset: 'assets/shop/panigale.png',
      tags: ['V4', 'Track'],
    ),
    _ShopItem(
      id: 'street_triple',
      name: 'Street Triple',
      maker: 'Triumph',
      priceINR: 179,
      thumbAsset: 'assets/shop/street_triple.png',
      tags: ['Naked', 'Inline-3'],
    ),
    _ShopItem(
      id: 'classic350',
      name: 'Classic 350',
      maker: 'Royal Enfield',
      priceINR: 99,
      thumbAsset: 'assets/shop/classic350.png',
      tags: ['Thump', 'Single'],
    ),
  ];

  final List<String> _categories = const [
    'All', 'Sport', 'Superbike', 'Naked', 'Twin', 'Inline-4', 'V4', 'Inline-3', 'Single', 'Thump', 'Track'
  ];
  String _selectedCategory = 'All';

  // UI-only state
  final Set<String> _purchased = {};
  final Set<String> _downloaded = {};



  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    const aiProductId = 'ai_sound_update';
    final purchaseProv = context.watch<PurchaseProvider>();
    final aiOwned = purchaseProv.isPurchased(aiProductId); // <-- adjust if your API differs

    final filtered = _selectedCategory == 'All'
        ? _catalog
        : _catalog
        .where((i) => i.tags.any((t) => t.toLowerCase() == _selectedCategory.toLowerCase()))
        .toList();

    // Make cards slightly taller to avoid tight squeezes on short screens
    final isSmallHeight = MediaQuery.of(context).size.height < 720;
    const childAspectRatio = 0.56;//isSmallHeight ? 0.1 : 0.74;

    return AppScaffold(
      title: 'Shop Sounds',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header + search (decorative for now)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Find your sound',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (q) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Search coming soon')),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Categories
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: _categories.map((c) {
                  final isSel = c == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: isSel,
                      onSelected: (_) => setState(() => _selectedCategory = c),
                      selectedColor: _accent.withOpacity(0.2),
                      side: BorderSide(color: isSel ? _accent : Colors.grey.shade700),
                      labelStyle: TextStyle(color: isSel ? _accent : Colors.white),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: _AiUpgradeCard(
                owned: aiOwned,
                onBuy: () async {
                  final ok = await purchaseProv.purchase(aiProductId); // <-- adjust method name if needed
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? 'AI Sound Update purchased' : 'Purchase failed')),
                    );
                  }
                },
                onLearnMore: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('AI Sound Update'),
                      content: const Text(
                        'Unlocks AI processing so your recorded sounds are automatically '
                            'segmented, leveled, and mapped to throttle (idle → revs → cruise). '
                            'No manual editing needed.',
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (_, i) {
                final item = filtered[i];
                final owned = _purchased.contains(item.id);
                final gotIt = _downloaded.contains(item.id);
                return _ShopCard(
                  item: item,
                  owned: owned,
                  downloaded: gotIt,
                  onPreview: () => _showPreview(context, item),
                  onBuy: owned
                      ? null
                      : () {
                    setState(() => _purchased.add(item.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Purchased ${item.name} (UI only)')),
                    );
                  },
                  onDownload: !owned || gotIt
                      ? null
                      : () {
                    setState(() => _downloaded.add(item.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Downloaded ${item.name} (UI only)')),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPreview(BuildContext context, _ShopItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // << important: allow tall content + drag
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.9,
            builder: (_, controller) => SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Thumb(thumbAsset: item.thumbAsset, size: 60),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                            Text(item.maker, style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: item.tags.map((t) => _Tag(t)).toList(),
                            ),
                          ],
                        ),
                      ),
                      _PricePill(priceINR: item.priceINR),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Preview audio coming soon…')),
                            );
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Preview'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShopItem {
  final String id;
  final String name;
  final String maker;
  final int priceINR;
  final String? thumbAsset;
  final List<String> tags;
  const _ShopItem({
    required this.id,
    required this.name,
    required this.maker,
    required this.priceINR,
    this.thumbAsset,
    this.tags = const [],
  });
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.item,
    required this.owned,
    required this.downloaded,
    required this.onPreview,
    required this.onBuy,
    required this.onDownload,
  });

  final _ShopItem item;
  final bool owned;
  final bool downloaded;
  final VoidCallback onPreview;
  final VoidCallback? onBuy;
  final VoidCallback? onDownload;

  static const _accent = Color(0xFFCC5500);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.2), Colors.white.withOpacity(0.04)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          onTap: onPreview,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min, // ⬅️ prevent expansion beyond grid tile height
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumb(thumbAsset: item.thumbAsset, size: 80),
                const SizedBox(height: 10),

                // Title & maker
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  item.maker,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),

                // Tags
                Wrap(
                  spacing: 6,
                  runSpacing: -6,
                  children: item.tags.take(3).map((t) => _Tag(t)).toList(),
                ),
                const SizedBox(height: 8),

                // Price + preview
                Row(
                  children: [
                    _PricePill(priceINR: item.priceINR),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Preview',
                      onPressed: onPreview,
                      icon: const Icon(Icons.play_arrow),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Buy / Download
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onBuy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: owned ? Colors.green : _accent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(36),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          owned ? 'Purchased' : 'Buy',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDownload,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: downloaded ? Colors.green : Colors.white24),
                          minimumSize: const Size.fromHeight(36),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          downloaded ? 'Installed' : 'Download',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _Thumb extends StatelessWidget {
  final String? thumbAsset;
  final double size;
  const _Thumb({this.thumbAsset, this.size = 72});

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(size / 3);
    return ClipRRect(
      borderRadius: border,
      child: thumbAsset == null
          ? Container(
        width: size,
        height: size,
        color: Colors.black26,
        alignment: Alignment.center,
        child: const Icon(Icons.motorcycle, size: 36),
      )
          : Image.asset(
        thumbAsset!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: Colors.black26,
          alignment: Alignment.center,
          child: const Icon(Icons.motorcycle, size: 36),
        ),
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  final int priceINR;
  const _PricePill({required this.priceINR});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text('₹$priceINR'),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _AiUpgradeCard extends StatelessWidget {
  const _AiUpgradeCard({
    required this.owned,
    required this.onBuy,
    required this.onLearnMore,
  });

  final bool owned;
  final Future<void> Function()? onBuy;
  final VoidCallback onLearnMore;

  static const _accent = Color(0xFFCC5500);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _accent.withOpacity(0.20),
              _accent.withOpacity(0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Row(
            children: [
              // Icon
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.auto_fix_high, size: 28),
              ),
              const SizedBox(width: 14),

              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Sound Update',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Record any exhaust (or any sound!) and auto-fit it to throttle dynamics.',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'One-time unlock • Works offline',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // CTA
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 128,
                    child: ElevatedButton(
                      onPressed: owned ? null : onBuy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: owned ? Colors.green : _accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(40),
                      ),
                      child: Text(owned ? 'Owned' : 'Buy'),
                    ),
                  ),
                  TextButton(
                    onPressed: onLearnMore,
                    child: const Text('Learn more'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
