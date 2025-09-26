import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:interactkids/widgets/game_exit_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:interactkids/widgets/animated_bubbles_background.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_game_base.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_models.dart';
import 'dart:math' as math;
import 'pictures_mode.dart';
import 'package:interactkids/widgets/bouncing_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Small decorative widgets used by the pictures screen to create
// non-rectangular, varied visuals (triangles, popsicles, cones, etc.)
class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.moveTo(size.width / 2, 0);
    p.lineTo(size.width, size.height);
    p.lineTo(0, size.height);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Simple editor screen to manage images for a custom set. It returns the
// final list of image file paths when popped.
class _CustomSetImageEditor extends StatefulWidget {
  final String keyId;
  final List<String> images;
  const _CustomSetImageEditor({required this.keyId, required this.images});

  @override
  State<_CustomSetImageEditor> createState() => _CustomSetImageEditorState();
}

class _CustomSetImageEditorState extends State<_CustomSetImageEditor> {
  late List<String> _images;

  @override
  void initState() {
    super.initState();
    _images = List<String>.from(widget.images);
  }

  Future<void> _addImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    final appDir = await getApplicationDocumentsDirectory();
    final destDir = Directory('${appDir.path}/custom_sets/${widget.keyId}');
    if (!destDir.existsSync()) destDir.createSync(recursive: true);
    for (final p in picked) {
      final file = File(p.path);
      final base = '${DateTime.now().millisecondsSinceEpoch}_${p.name}';
      final dest = File('${destDir.path}/$base');
      await file.copy(dest.path);
      _images.add(dest.path);
    }
    if (mounted) setState(() {});
  }

  void _removeAt(int idx) {
    if (idx < 0 || idx >= _images.length) return;
    _images.removeAt(idx);
    if (mounted) setState(() {});
  }

  void _moveLeft(int idx) {
    if (idx <= 0 || idx >= _images.length) return;
    final v = _images.removeAt(idx);
    _images.insert(idx - 1, v);
    if (mounted) setState(() {});
  }

  void _moveRight(int idx) {
    if (idx < 0 || idx >= _images.length - 1) return;
    final v = _images.removeAt(idx);
    _images.insert(idx + 1, v);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Use PopScope (available on newer Flutter SDKs) to handle back navigation
    // and provide the popped result. This replaces deprecated WillPopScope.
    return WillPopScope(
      onWillPop: () async {
        // Ensure that when the user presses Back we return the current image
        // list to the caller (there is no separate Save button).
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(_images);
          // Returning true allows the pop to complete; we've already supplied
          // the result via pop above.
          return true;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_labelForKey(widget.keyId)),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_photo_alternate),
              onPressed: _addImages,
              tooltip: 'Add images',
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(_images),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
        body: _images.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No images yet. Tap + to add images.'),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                        onPressed: _addImages,
                        icon: const Icon(Icons.add),
                        label: const Text('Add images'))
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(12.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (ctx, idx) {
                    final path = _images[idx];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade100,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(path), fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Row(
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.arrow_back_ios, size: 16),
                                color: Colors.white,
                                onPressed:
                                    idx == 0 ? null : () => _moveLeft(idx),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios,
                                    size: 16),
                                color: Colors.white,
                                onPressed: idx == _images.length - 1
                                    ? null
                                    : () => _moveRight(idx),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                color: Colors.redAccent,
                                onPressed: () => _removeAt(idx),
                              ),
                            ],
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }

  String _labelForKey(String key) {
    // attempt to present user-friendly name
    if (key.startsWith('custom-')) {
      final parts = key.split('-');
      if (parts.length > 1) return 'Set ${parts.last}';
    }
    return key;
  }
}

class _TriangleBadge extends StatelessWidget {
  final Color color;
  final double size;
  const _TriangleBadge({this.color = Colors.orange, this.size = 100});
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _TriangleClipper(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            color.withAlpha((0.9 * 255).round()),
            color.withAlpha((0.6 * 255).round())
          ]),
          boxShadow: [
            BoxShadow(
                color: color.withAlpha(60),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: null,
      ),
    );
  }
}

// Themed, animated category card used on the initial selection screen.
class _CategoryCard extends StatefulWidget {
  final String label;
  final Color color;
  final Widget visual;
  final VoidCallback onTap;
  const _CategoryCard(
      {required this.label,
      required this.color,
      required this.visual,
      required this.onTap});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBouncingButton(
      onTap: widget.onTap,
      delay: (widget.label.hashCode % 3) * 120,
      width: 160,
      height: 160,
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            widget.color.withAlpha((0.98 * 255).round()),
            widget.color
          ]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: widget.color.withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 84, height: 84, child: widget.visual),
            const SizedBox(height: 10),
            Text(widget.label,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// Decorative classes for pizza/popsicle/cone were removed because they
// include multi-part visuals (sticks/triangles) which could appear as
// separate attached elements in the matching grid. We now use solid
// single-piece shapes in the categories so matching is clean.

class MatchingPicturesScreen extends StatefulWidget {
  const MatchingPicturesScreen({super.key});
  @override
  State<MatchingPicturesScreen> createState() => _MatchingPicturesScreenState();
}

class _MatchingPicturesScreenState extends State<MatchingPicturesScreen> {
  String? _selectedCategory;
  String? _selectedDifficulty;
  GlobalKey<MatchingGameBaseState> _gameKey =
      GlobalKey<MatchingGameBaseState>();
  // Map of custom set keys to their base selection ('set1'|'set2'|'all')
  final Map<String, String> _customSetMapping = {};
  int _customSetCounter = 1;
  // Optional user-facing names for custom sets (e.g. custom-3 -> "Set 3" or "My Set")
  final Map<String, String> _customSetNames = {};
  // Map custom set key -> category (e.g. custom-3 -> 'Fruits') so custom sets
  // are scoped to the category they were created for.
  final Map<String, String> _customSetCategory = {};
  bool _prefsLoaded = false;
  // Map custom set key -> list of local file paths for images
  final Map<String, List<String>> _customSetImages = {};

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Load persisted custom sets immediately so the initial build can
    // create the MatchingGameBase with the correct progress key.
    _loadPersistedCustomSets().whenComplete(() {
      // After prefs loaded, load asset lists on the next frame (asset loading
      // uses DefaultAssetBundle which is available after build).
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAssetLists());
    });
  }

  Future<void> _loadPersistedCustomSets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('custom_sets_v1');
      final namesJson = prefs.getString('custom_set_names_v1');
      final counter = prefs.getInt('custom_sets_counter');
      // We intentionally do not restore last_selected_category/last_selected_difficulty
      // on startup; the user should pick a category first. Do not read these
      // prefs to avoid unused local variables.
      if (jsonStr != null) {
        final Map<String, dynamic> decoded = json.decode(jsonStr);
        _customSetMapping.clear();
        decoded.forEach((k, v) {
          if (v is String) _customSetMapping[k] = v;
        });
      }
      final catJson = prefs.getString('custom_set_category_v1');
      if (catJson != null) {
        final Map<String, dynamic> decodedCats = json.decode(catJson);
        _customSetCategory.clear();
        decodedCats.forEach((k, v) {
          if (v is String) _customSetCategory[k] = v;
        });
      }
      if (namesJson != null) {
        final Map<String, dynamic> decodedNames = json.decode(namesJson);
        _customSetNames.clear();
        decodedNames.forEach((k, v) {
          if (v is String) _customSetNames[k] = v;
        });
      }
      final imagesJson = prefs.getString('custom_set_images_v1');
      if (imagesJson != null) {
        final Map<String, dynamic> decodedImages = json.decode(imagesJson);
        _customSetImages.clear();
        decodedImages.forEach((k, v) {
          if (v is List) {
            _customSetImages[k] = v.map((e) => e.toString()).toList();
          }
        });
      }
      if (counter != null) _customSetCounter = counter;
      // Only restore last selection if the user has previously seen the
      // category chooser (flag set). This avoids auto-entering gameplay for
      // first-time users while still restoring last state for returning users.
      final seenChooser = prefs.getBool('seen_category_chooser_v1') ?? false;
      if (seenChooser) {
        final lastCat = prefs.getString('last_selected_category');
        final lastDiff = prefs.getString('last_selected_difficulty');
        if (lastCat != null) _selectedCategory = lastCat;
        if (lastDiff != null) _selectedDifficulty = lastDiff;
      }
      // If we have a last category and there is a stored progress entry for
      // a custom set (for example matching_pictures_progress_<Category>_custom-3)
      // prefer that stored key so the app reopens the set with saved progress.
      try {
        if (_selectedCategory != null) {
          final prefsKeys = prefs.getKeys();
          // Build prefix used by MatchingPicturesMode
          final prefix = 'matching_pictures_progress_${_selectedCategory!}_';
          String? foundSuffix;
          for (final k in prefsKeys) {
            if (k.startsWith(prefix)) {
              // Ensure there is actually stored data for this key
              final list = prefs.getStringList(k);
              if (list != null && list.isNotEmpty) {
                // suffix is everything after the category_
                foundSuffix = k.substring(prefix.length);
                break;
              }
            }
          }

          // foundSuffix must belong to the selected category (avoid restoring
          // a custom set that was created for another category)
          if (foundSuffix != null) {
            if (foundSuffix.startsWith('custom-')) {
              final cat = _customSetCategory[foundSuffix];
              if (cat == _selectedCategory) {
                _selectedDifficulty = foundSuffix;
              }
            } else {
              _selectedDifficulty = foundSuffix;
            }
          }
        }
      } catch (_) {}
      _prefsLoaded = true;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Failed to load persisted custom sets: $e');
      _prefsLoaded = true;
      if (mounted) setState(() {});
    }
  }

  Future<void> _savePersistedCustomSets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(_customSetMapping);
      final encodedNames = json.encode(_customSetNames);
      await prefs.setString('custom_sets_v1', encoded);
      await prefs.setString('custom_set_names_v1', encodedNames);
      final encodedImages = json.encode(_customSetImages);
      await prefs.setString('custom_set_images_v1', encodedImages);
      final encodedCats = json.encode(_customSetCategory);
      await prefs.setString('custom_set_category_v1', encodedCats);
      await prefs.setInt('custom_sets_counter', _customSetCounter);
      if (_selectedCategory != null) {
        await prefs.setString('last_selected_category', _selectedCategory!);
      }
      if (_selectedDifficulty != null) {
        await prefs.setString('last_selected_difficulty', _selectedDifficulty!);
      }

      // Mark chooser seen only if both category and difficulty are chosen
      // and there's at least one pair to play. This indicates the user has
      // effectively started a game.
      try {
        if (_selectedCategory != null && _selectedDifficulty != null) {
          final pairs = _makePairsForCategory(_selectedCategory!);
          if (pairs.isNotEmpty) {
            await prefs.setBool('seen_category_chooser_v1', true);
          }
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('Failed to save custom sets: $e');
    }
  }

  Future<void> _pickImagesForCurrentSet() async {
    if (_selectedDifficulty == null) return;
    // If the currently selected difficulty is an existing custom set, attach
    // directly to it (fast path). Otherwise show a chooser that only allows
    // creating or selecting a custom set for this category.
    String key;
    if (_selectedDifficulty!.startsWith('custom-') &&
        _customSetMapping.containsKey(_selectedDifficulty!)) {
      key = _selectedDifficulty!;
    } else {
      // Build list of available custom sets for this category
      final available = _customSetMapping.keys.where((k) {
        return k.startsWith('custom-') &&
            (_customSetCategory[k] == null ||
                _customSetCategory[k] == _selectedCategory);
      }).toList();

      final chosen = await showModalBottomSheet<String?>(
          context: context,
          builder: (ctx) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Create new set'),
                    leading: const Icon(Icons.add),
                    onTap: () => Navigator.of(ctx).pop('_new_'),
                  ),
                  const Divider(),
                  ...available.map((k) {
                    final label = _labelForLevel(k);
                    final imgs = _customSetImages[k] ?? [];
                    Widget leading;
                    if (imgs.isNotEmpty && File(imgs.first).existsSync()) {
                      leading = ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(imgs.first),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      );
                    } else {
                      leading = const Icon(Icons.collections, size: 36);
                    }
                    return ListTile(
                      leading: leading,
                      title: Text(label),
                      subtitle: Text(_customSetCategory[k] ?? ''),
                      onTap: () => Navigator.of(ctx).pop(k),
                    );
                  }).toList(),
                  ListTile(
                    leading: const Icon(Icons.close),
                    title: const Text('Cancel'),
                    onTap: () => Navigator.of(ctx).pop(null),
                  )
                ],
              ),
            );
          });
      if (chosen == null) return;
      if (chosen == '_new_') {
        key = _createCustomSet();
        await _savePersistedCustomSets();
      } else {
        key = chosen;
      }
    }

    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;

    final appDir = await getApplicationDocumentsDirectory();
    final destDir = Directory('${appDir.path}/custom_sets/$key');
    if (!destDir.existsSync()) destDir.createSync(recursive: true);

    final savedPaths = _customSetImages[key] ?? [];
    for (final f in picked) {
      final file = File(f.path);
      final base = '${DateTime.now().millisecondsSinceEpoch}_${f.name}';
      final dest = File('${destDir.path}/$base');
      await file.copy(dest.path);
      savedPaths.add(dest.path);
    }
    _customSetImages[key] = savedPaths;
    // If this custom set was a new empty sentinel, mark it as a real custom
    // set that maps to a sensible base (set1) so visibility checks behave.
    if (_customSetMapping.containsKey(key) &&
        _customSetMapping[key] == 'empty') {
      _customSetMapping[key] = 'set1';
    }
    debugPrint('PicturesScreen: saved ${savedPaths.length} images for $key');
    await _savePersistedCustomSets();
    // recreate the game key to force MatchingGameBase to remount and pick up
    // the new visuals and pairs.
    _gameKey = GlobalKey<MatchingGameBaseState>();
    if (mounted) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(SnackBar(
          content: Text(
              'Saved ${savedPaths.length} image(s) to ${_labelForLevel(key)}')));
      setState(() {});
    }
  }

  // Open an image editor screen for a given custom set key. The editor
  // allows previewing, adding, removing, and reordering images. When the
  // editor returns it will persist any changes and update the UI.
  Future<void> _openCustomSetEditor(String key) async {
    final result =
        await Navigator.of(context).push<List<String?>>(MaterialPageRoute(
      builder: (ctx) => _CustomSetImageEditor(
        keyId: key,
        images: List<String>.from(_customSetImages[key] ?? []),
      ),
    ));
    if (result != null) {
      // Filter out nulls and update persisted mapping
      final updated = result.whereType<String>().toList();
      // Remove any files that were removed in the editor and live under
      // the app's custom_sets/<key> directory.
      try {
        final previous = List<String>.from(_customSetImages[key] ?? []);
        final removed = previous.where((p) => !updated.contains(p)).toList();
        if (removed.isNotEmpty) {
          final appDir = await getApplicationDocumentsDirectory();
          final setDir = Directory('${appDir.path}/custom_sets/$key');
          for (final p in removed) {
            try {
              final f = File(p);
              if (f.existsSync()) {
                // Only delete files that are inside the set directory to avoid
                // accidentally deleting user files from elsewhere.
                if (f.parent.path.startsWith(setDir.path)) {
                  await f.delete();
                }
              }
            } catch (_) {}
          }
        }
      } catch (_) {}

      // If this custom set was previously an 'empty' sentinel, and the
      // editor returned images, mark it as a real custom set so it becomes
      // visible in the UI immediately.
      if (updated.isNotEmpty &&
          (_customSetMapping[key] == null ||
              _customSetMapping[key] == 'empty')) {
        _customSetMapping[key] = 'set1';
      }
      _customSetImages[key] = updated;
      await _savePersistedCustomSets();
      // Recreate the game key so MatchingGameBase remounts and reloads the
      // pairs/visuals based on the updated images.
      _gameKey = GlobalKey<MatchingGameBaseState>();
      if (mounted) setState(() {});
    }
  }

  // ...existing code...

  // Cached lists of asset paths discovered in AssetManifest.json
  final Map<String, List<String>> _assetsByFolder = {};

  Future<void> _loadAssetLists() async {
    try {
      final manifestJson =
          await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestJson);
      final fruits = <String>[];
      final vegetables = <String>[];
      final allowedExts = {'.png', '.jpg', '.jpeg', '.gif', '.bmp'};
      for (final key in manifestMap.keys) {
        final lowerKey = key.toLowerCase();
        final ext = lowerKey.contains('.')
            ? lowerKey.substring(lowerKey.lastIndexOf('.'))
            : '';
        // Skip non-image files (dotfiles, placeholders)
        final base = key.split(RegExp(r'[\\/]')).last;
        if (base.startsWith('.')) continue;

        // Helper to prefer processed asset if it exists in the manifest
        String pickPreferred(String originalPath) {
          final processedPath =
              originalPath.replaceFirst('assets/images', 'assets/processed');
          // manifestMap keys are the original manifest entries; check case-insensitively
          if (manifestMap.keys
              .any((k) => k.toLowerCase() == processedPath.toLowerCase())) {
            // find the actual key with original casing
            final found = manifestMap.keys.firstWhere(
                (k) => k.toLowerCase() == processedPath.toLowerCase());
            return found;
          }
          return originalPath;
        }

        if (lowerKey.startsWith('assets/images/fruits/') &&
            allowedExts.contains(ext)) {
          final preferred = pickPreferred(key);
          // validate asset by trying to load its bytes and instantiate an image codec
          try {
            final bd = await rootBundle.load(preferred);
            final bytes = bd.buffer.asUint8List();
            await ui.instantiateImageCodec(bytes);
            fruits.add(preferred);
          } catch (e) {
            debugPrint('Skipping invalid fruit asset $preferred: $e');
          }
        }
        if (lowerKey.startsWith('assets/images/vegetables/') &&
            allowedExts.contains(ext)) {
          final preferred = pickPreferred(key);
          try {
            final bd = await rootBundle.load(preferred);
            final bytes = bd.buffer.asUint8List();
            await ui.instantiateImageCodec(bytes);
            vegetables.add(preferred);
          } catch (e) {
            debugPrint('Skipping invalid vegetable asset $preferred: $e');
          }
        }
      }
      fruits.sort();
      vegetables.sort();
      debugPrint(
          'PicturesScreen: discovered assets - fruits=${fruits.length}, vegetables=${vegetables.length}');
      setState(() {
        _assetsByFolder['fruits'] = fruits;
        _assetsByFolder['vegetables'] = vegetables;
      });
      debugPrint('PicturesScreen: _assetsByFolder updated and setState called');
    } catch (e) {
      // Ignore manifest loading errors; fallback to static lists.
      debugPrint('Could not load AssetManifest: $e');
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // Widgets grouped by difficulty: easy (large), medium, hard (small)
  // Made non-const so we can use richer, non-const decorated widgets for easy shapes
  static final Map<String, Map<String, List<Widget>>> _categoryWidgets = {
    'Fruits': {
      'easy': [
        // Use real fruit images from assets for the Easy level. Place your
        // images in assets/images/fruits/ (e.g. apple.png, banana.png).
        // Wrap in Center to match other category visuals sizing.
        // Use the uploaded real fruit images which live under
        // assets/images/fruits/Fruits/ (user-uploaded). Keep a fixed
        // size so the category visuals remain consistent.
        Center(
            child: SizedBox(
                width: 160,
                height: 160,
                child: Image.asset('assets/images/fruits/Fruits/apple.png',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, e, st) =>
                        const Center(child: Icon(Icons.broken_image))))),
        Center(
            child: SizedBox(
                width: 160,
                height: 160,
                child: Image.asset('assets/images/fruits/Fruits/banana.png',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, e, st) =>
                        const Center(child: Icon(Icons.broken_image))))),
        Center(
            child: SizedBox(
                width: 160,
                height: 160,
                child: Image.asset('assets/images/fruits/Fruits/cherry.png',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, e, st) =>
                        const Center(child: Icon(Icons.broken_image))))),
        Center(
            child: SizedBox(
                width: 160,
                height: 160,
                child: Image.asset('assets/images/fruits/Fruits/kiwi.png',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, e, st) =>
                        const Center(child: Icon(Icons.broken_image))))),
        Center(
            child: SizedBox(
                width: 160,
                height: 160,
                child: Image.asset('assets/images/fruits/Fruits/lemon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, e, st) =>
                        const Center(child: Icon(Icons.broken_image))))),
        Center(
            child: SizedBox(
                width: 160,
                height: 160,
                child: Image.asset('assets/images/fruits/Fruits/orange.png',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, e, st) =>
                        const Center(child: Icon(Icons.broken_image))))),
        Center(
            child: SizedBox(
                width: 160,
                height: 160,
                child: Image.asset('assets/images/fruits/Fruits/payaya.png',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, e, st) =>
                        const Center(child: Icon(Icons.broken_image))))),
        Center(
            child: SizedBox(
                width: 160,
                height: 160,
                child: Image.asset('assets/images/fruits/Fruits/pineapple.png',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, e, st) =>
                        const Center(child: Icon(Icons.broken_image))))),
        Center(
            child: SizedBox(
                width: 160,
                height: 160,
                child: Image.asset('assets/images/fruits/Fruits/strawberry.png',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, e, st) =>
                        const Center(child: Icon(Icons.broken_image))))),
        Center(
            child: SizedBox(
                width: 160,
                height: 160,
                child: Image.asset('assets/images/fruits/Fruits/watermelon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, e, st) =>
                        const Center(child: Icon(Icons.broken_image))))),
      ],
      'medium': [
        // Move previous large emoji/graphic hints to Medium level for variety
        const Center(child: Text('�', style: TextStyle(fontSize: 72))),
        const Center(child: Text('�', style: TextStyle(fontSize: 72))),
        // Fruit-like colored blocks with emoji inside for variety
        Container(
            width: 96,
            height: 72,
            decoration: BoxDecoration(
                color: Colors.orangeAccent,
                borderRadius: BorderRadius.circular(12)),
            child: const Center(
                child: Text('🥭', style: TextStyle(fontSize: 36)))),
        Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
                color: Colors.redAccent.shade200,
                borderRadius: BorderRadius.circular(16)),
            child: const Center(
                child: Text('🍓', style: TextStyle(fontSize: 36)))),
        Container(
            width: 88,
            height: 56,
            decoration: BoxDecoration(
                color: Colors.yellow.shade700,
                borderRadius: BorderRadius.circular(28)),
            child: const Center(
                child: Text('🍊', style: TextStyle(fontSize: 28)))),
        // Triangle badge retained but tuned for a fruity color
        const _TriangleBadge(color: Colors.pinkAccent, size: 100),
        // Circle with lemon emoji
        Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
                color: Colors.yellow, shape: BoxShape.circle),
            child: const Center(
                child: Text('🍋', style: TextStyle(fontSize: 36)))),
      ],
      'hard': [
        const Center(child: Text('🍒', style: TextStyle(fontSize: 48))),
        // small colored block as a neutral 'fruit hint'
        Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: Colors.blueGrey, borderRadius: BorderRadius.circular(8)),
            child: const Center(
                child: Text('🥝', style: TextStyle(fontSize: 20)))),
      ],
    },
    'Vegetables': {
      'easy': [
        // Use uploaded vegetable images from assets/images/vegetables/ for Easy
        Center(
            child: SizedBox(
                width: 160,
                height: 160,
                child: Image.asset('assets/images/vegetables/tomato.png',
                    fit: BoxFit.contain))),
        Center(
            child: SizedBox(
                width: 160,
                height: 160,
                child: Image.asset('assets/images/vegetables/carrots.png',
                    fit: BoxFit.contain))),
        Center(
            child: SizedBox(
                width: 160,
                height: 160,
                child: Image.asset('assets/images/vegetables/pumpkin.png',
                    fit: BoxFit.contain))),
        Center(
            child: SizedBox(
                width: 160,
                height: 160,
                child: Image.asset('assets/images/vegetables/eggplant.png',
                    fit: BoxFit.contain))),
        Center(
            child: SizedBox(
                width: 160,
                height: 160,
                child: Image.asset('assets/images/vegetables/broc.png',
                    fit: BoxFit.contain))),
      ],
      'medium': [
        const Icon(Icons.grass, size: 72, color: Colors.green),
        // Keep previous easy visuals available in medium for familiarity
        const Icon(Icons.eco, size: 100, color: Colors.greenAccent),
        Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                color: Colors.lightGreen,
                borderRadius: BorderRadius.circular(12)),
            child: const Center(
                child: Text('🥕', style: TextStyle(fontSize: 36)))),
        const CircleAvatar(
            radius: 48,
            backgroundColor: Colors.green,
            child: Text('🥦', style: TextStyle(fontSize: 36))),
      ],
      'hard': [const Icon(Icons.spa, size: 48, color: Colors.lightGreen)],
    },
    'Colors': {
      'easy': [
        const ColoredBox(
            color: Colors.red, child: SizedBox(width: 100, height: 100)),
        const ColoredBox(
            color: Colors.orange, child: SizedBox(width: 100, height: 100)),
        const ColoredBox(
            color: Colors.yellow, child: SizedBox(width: 100, height: 100)),
        const ColoredBox(
            color: Colors.green, child: SizedBox(width: 100, height: 100)),
      ],
      'medium': [
        const ColoredBox(
            color: Colors.green, child: SizedBox(width: 72, height: 72))
      ],
      'hard': [
        const ColoredBox(
            color: Colors.blue, child: SizedBox(width: 48, height: 48)),
        const ColoredBox(
            color: Colors.yellow, child: SizedBox(width: 48, height: 48))
      ],
    },
    'Shapes': {
      'easy': [
        // Solid indigo circle (responsive)
        LayoutBuilder(builder: (ctx, c) {
          final s = math.min(c.maxWidth, c.maxHeight) * 0.95;
          return Center(
              child: Container(
                  width: s,
                  height: s,
                  decoration: const BoxDecoration(
                      color: Colors.indigo, shape: BoxShape.circle)));
        }),
        // Solid rounded square
        LayoutBuilder(builder: (ctx, c) {
          final s = math.min(c.maxWidth, c.maxHeight) * 0.95;
          return Center(
              child: Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(s * 0.12))));
        }),
        // Solid triangle badge
        LayoutBuilder(builder: (ctx, c) {
          final s = math.min(c.maxWidth, c.maxHeight) * 0.95;
          return Center(
              child: ClipPath(
                  clipper: _TriangleClipper(),
                  child: Container(
                      width: s,
                      height: s,
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              colors: [Colors.orange, Colors.deepOrange])))));
        }),
        // Solid star (icon-shaped)
        LayoutBuilder(builder: (ctx, c) {
          final s = math.min(c.maxWidth, c.maxHeight) * 0.9;
          return Center(child: Icon(Icons.star, size: s, color: Colors.amber));
        }),
        // Solid pink circle
        LayoutBuilder(builder: (ctx, c) {
          final s = math.min(c.maxWidth, c.maxHeight) * 0.95;
          return Center(
              child: Container(
                  width: s,
                  height: s,
                  decoration: const BoxDecoration(
                      color: Colors.pinkAccent, shape: BoxShape.circle)));
        }),
        // Teal rounded box
        LayoutBuilder(builder: (ctx, c) {
          final s = math.min(c.maxWidth, c.maxHeight) * 0.95;
          return Center(
              child: Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(s * 0.12),
                      border: Border.all(
                          color: Colors.teal.shade700, width: s * 0.04))));
        }),
        // Diamond (rotated square)
        LayoutBuilder(builder: (ctx, c) {
          final s = math.min(c.maxWidth, c.maxHeight) * 0.9;
          return Center(
              child: Transform.rotate(
                  angle: 0.785398,
                  child: Container(
                      width: s, height: s, color: Colors.blueAccent)));
        }),
        // Gradient rounded square
        LayoutBuilder(builder: (ctx, c) {
          final s = math.min(c.maxWidth, c.maxHeight) * 0.95;
          return Center(
              child: Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Colors.purple, Colors.blue]),
                      borderRadius: BorderRadius.circular(s * 0.12))));
        }),
        // Ringed circle (solid center)
        LayoutBuilder(builder: (ctx, c) {
          final s = math.min(c.maxWidth, c.maxHeight) * 0.95;
          return Center(
              child: Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.orange, width: s * 0.07))));
        }),
        // Hexagon-like solid shape (rotated rounded rect)
        LayoutBuilder(builder: (ctx, c) {
          final s = math.min(c.maxWidth, c.maxHeight) * 0.9;
          return Center(
              child: Transform.rotate(
                  angle: 0.26,
                  child: Container(
                      width: s,
                      height: s * 0.72,
                      decoration: BoxDecoration(
                          color: Colors.lime,
                          borderRadius: BorderRadius.circular(s * 0.12)))));
        }),
      ],
      'medium': [const Icon(Icons.square_foot, size: 72, color: Colors.brown)],
      'hard': [
        const Icon(Icons.change_history, size: 48, color: Colors.pink),
        const Icon(Icons.crop_square, size: 48, color: Colors.cyan)
      ],
    },
  };

  List<MatchingPair> _makePairsForCategory(String category) {
    // If easy difficulty and we have dynamic assets for fruits/vegetables,
    // use those asset counts to generate pairs so newly added images are
    // automatically included.
    final groups = _categoryWidgets[category] ?? {};
    final items = <String>[];
    // If the currently selected difficulty is a custom set with stored
    // images, and that custom set belongs to this category, produce pairs
    // directly from those images so they appear immediately in the matching
    // grid.
    if (_selectedDifficulty != null &&
        _selectedDifficulty!.startsWith('custom-')) {
      final key = _selectedDifficulty!;
      // Only use this custom set if it was created for this category.
      if (_customSetCategory[key] != null &&
          _customSetCategory[key] != category) {
        // Not for this category; fall through to default handling.
      } else {
        final imgs = _customSetImages[key];
        if (imgs != null && imgs.isNotEmpty) {
          for (var i = 0; i < imgs.length; i++) {
            items.add('$category-$key-$i');
          }
          return items.map((id) => MatchingPair(left: id, right: id)).toList();
        }
        // If custom set is empty, return empty list of pairs.
        return <MatchingPair>[];
      }
    }
    // If 'easy' visuals are visible for the current selection (Set 1)
    if ((_isDifficultyVisible('easy')) &&
        (category == 'Fruits' || category == 'Vegetables')) {
      final key = category == 'Fruits' ? 'fruits' : 'vegetables';
      final assets = _assetsByFolder[key];
      if (assets != null && assets.isNotEmpty) {
        for (var i = 0; i < assets.length; i++) {
          items.add('$category-easy-$i');
        }
        return items.map((id) => MatchingPair(left: id, right: id)).toList();
      }
    }

    for (final entry in groups.entries) {
      final difficulty = entry.key;
      if (!_isDifficultyVisible(difficulty)) continue;
      // If the selected difficulty is a custom set mapped to 'empty' then
      // there are no pairs to show until images are added.
      if (difficulty.startsWith('custom-') &&
          _customSetMapping[difficulty] == 'empty') {
        continue;
      }
      for (var i = 0; i < entry.value.length; i++) {
        items.add('$category-$difficulty-$i');
      }
    }
    return items.map((id) => MatchingPair(left: id, right: id)).toList();
  }

  // Helper to decide whether a given difficulty (easy/medium/hard) should be
  // shown given the user's selection of set1/set2/all.
  bool _isDifficultyVisible(String difficulty) {
    // If the selected difficulty is a custom set, map it to its base selection
    String selected = _selectedDifficulty ?? 'all';
    if (_customSetMapping.containsKey(selected)) {
      selected = _customSetMapping[selected]!;
    }

    if (selected == 'all') {
      return true;
    }
    if (selected == 'set1') {
      return difficulty == 'easy';
    }
    if (selected == 'set2') {
      return difficulty == 'medium' || difficulty == 'hard';
    }
    // fallback: match exact
    return difficulty == selected;
  }

  String _displayLabel(String key) {
    // Use the raw category name as the display label (no swapping).
    return key;
  }

  String _labelForLevel(String key) {
    if (key == 'set1') return 'Set 1';
    if (key == 'set2') return 'Set 2';
    if (key == 'all') return 'All';
    // custom sets are stored like 'custom-<n>' or similar; display as 'Set N'
    if (_customSetMapping.containsKey(key)) {
      // Prefer a stored display name if provided
      if (_customSetNames.containsKey(key) &&
          _customSetNames[key]!.isNotEmpty) {
        return _customSetNames[key]!;
      }
      // try to extract trailing number
      final parts = key.split('-');
      if (parts.length > 1) return 'Set ${parts.last}';
      return key;
    }
    return key;
  }

  String _createCustomSet({bool selectNow = true}) {
    // Determine base selection from current selection (map custom->base if needed)
    String base = _selectedDifficulty ?? 'set1';
    if (_customSetMapping.containsKey(base)) base = _customSetMapping[base]!;
    // find the smallest available custom id for THIS CATEGORY (reuse deleted
    // numbers inside the same category). Reserve 1 and 2 for set1/set2;
    // custom indices start at 3. Keys must still be globally unique, so we
    // include a slugified category in the key (custom-<slug>-<n>) to avoid
    // collisions between different categories while keeping the displayed
    // label as 'Set N'.
    final used = <int>{};
    for (final k in _customSetMapping.keys) {
      // consider only keys that belong to the selected category
      final catForKey = _customSetCategory[k];
      if (catForKey == null || _selectedCategory == null) continue;
      if (catForKey != _selectedCategory) continue;
      // try to find a trailing number in the key (works for both
      // old-style 'custom-3' and new-style 'custom-fruits-3')
      final parts = k.split('-');
      if (parts.isNotEmpty) {
        final maybe = parts.last;
        final n = int.tryParse(maybe);
        if (n != null) used.add(n);
      }
    }
    var idx = 3;
    while (used.contains(idx)) idx++;

    // slugify the category to produce a globally unique key
    String _slugify(String s) {
      return s
          .toLowerCase()
          .replaceAll(RegExp(r"[^a-z0-9]+"), '-')
          .replaceAll(RegExp(r'(^-|-$)'), '');
    }

    final slug = _selectedCategory != null ? _slugify(_selectedCategory!) : 'misc';
    final key = 'custom-$slug-$idx';
    // New custom sets should start empty (no pre-populated pairs). Store
    // a sentinel value 'empty' so the UI generation code will produce no
    // pairs for this custom set until the user adds images.
    _customSetMapping[key] = 'empty';
    // Record the category for this custom set so it does not appear in other categories
    if (_selectedCategory != null) {
      _customSetCategory[key] = _selectedCategory!;
    }
    // Do not overwrite _customSetNames here — if the user renames a set we
    // store their name in _customSetNames; otherwise derive the display
    // label from the numeric index in the key (so deleted numbers are reused
    // consistently). Ensure the counter is at least past this idx.
  if (_customSetCounter <= idx) _customSetCounter = idx + 1;
    // Ensure a stable default display name for newly created sets so the
    // UI doesn't appear to increment names unexpectedly. Do not overwrite
    // if the user has already set a custom name.
    if (!_customSetNames.containsKey(key) ||
        (_customSetNames[key] ?? '').isEmpty) {
      _customSetNames[key] = 'Set $idx';
    }
    // persist
    _savePersistedCustomSets();
    if (selectNow) {
      setState(() {
        _selectedDifficulty = key;
      });
    }
    // MatchingGameBase will reload saved progress when the progressKey changes.
    return key;
  }

  void _showCustomSetMenu(String key) async {
    final choice = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () => Navigator.of(ctx).pop('rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(ctx).pop(null),
            ),
          ],
        ),
      ),
    );
    if (choice == 'rename') {
      _renameCustomSet(key);
    } else if (choice == 'delete') {
      _deleteCustomSet(key);
    }
  }

  void _renameCustomSet(String key) async {
    final controller = TextEditingController(text: _customSetNames[key] ?? '');
    final newName = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename set'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Set name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (newName != null) {
      setState(() {
        _customSetNames[key] = newName;
      });
      await _savePersistedCustomSets();
    }
  }

  void _deleteCustomSet(String key) async {
    final confirmed = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete custom set?'),
        content: const Text(
            'This will remove the custom set and its saved progress.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _customSetMapping.remove(key);
        _customSetNames.remove(key);
        _customSetCategory.remove(key);
        // Remove any in-memory image list for this set so the index is free
        _customSetImages.remove(key);
        if (_selectedDifficulty == key) {
          _selectedDifficulty = 'set1';
        }
      });
      await _savePersistedCustomSets();
      // Also remove any copied files for this custom set from app storage
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final dir = Directory('${appDir.path}/custom_sets/$key');
        if (dir.existsSync()) {
          await dir.delete(recursive: true);
        }
      } catch (_) {}
      // Let MatchingGameBase reload saved progress when it rebuilds with the
      // new mode/progressKey (didUpdateWidget handles reloading). Do not
      // call resetGame here since that removes persisted progress.
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categoryWidgets.keys.toList();
    final pairs = _selectedCategory == null
        ? <MatchingPair>[]
        : _makePairsForCategory(_selectedCategory!);
    final visuals = <String, Widget>{};
    final groups = _selectedCategory == null
        ? {}
        : _categoryWidgets[_selectedCategory!] ?? {};
    // If the currently selected difficulty is a custom set and we have
    // stored images for it, build visuals directly from those images so
    // the matching grid shows them immediately.
    if (_selectedCategory != null &&
        _selectedDifficulty != null &&
        _selectedDifficulty!.startsWith('custom-') &&
        _customSetImages.containsKey(_selectedDifficulty)) {
      final key = _selectedDifficulty!;
      // Only show the custom set visuals if this custom set belongs to the
      // currently selected category.
      if (_customSetCategory[key] == null ||
          _customSetCategory[key] == _selectedCategory) {
        final imgs = _customSetImages[_selectedDifficulty!]!;
        for (var i = 0; i < imgs.length; i++) {
          final id = '$_selectedCategory-${_selectedDifficulty!}-$i';
          final path = imgs[i];
          visuals[id] = SizedBox(
              width: 120,
              height: 120,
              child:
                  Center(child: Image.file(File(path), fit: BoxFit.contain)));
        }
      }
      // We intentionally skip the default groups visuals since the custom
      // selection is specific to this custom set.
    } else {
      groups.forEach((difficulty, widgets) {
        if (!_isDifficultyVisible(difficulty)) return;
        if (difficulty == 'easy' &&
            (_selectedCategory == 'Fruits' ||
                _selectedCategory == 'Vegetables')) {
          // If we have dynamic assets for this category, generate one visual per
          // discovered asset so newly added images show up automatically.
          final key = _selectedCategory == 'Fruits' ? 'fruits' : 'vegetables';
          final list = _assetsByFolder[key];
          if (list != null && list.isNotEmpty) {
            for (var i = 0; i < list.length; i++) {
              final id = '$_selectedCategory-$difficulty-$i';
              final assetPath = list[i];
              final w = SizedBox(
                  width: 120,
                  height: 120,
                  child: Center(
                      child: Image.asset(assetPath, fit: BoxFit.contain)));
              visuals[id] = w;
            }
            return; // done with this difficulty
          }
        }
        // If this difficulty corresponds to a custom set that has stored images,
        // show those images instead of the default widget list.
        if (difficulty.startsWith('custom-') &&
            _customSetCategory[difficulty] != null &&
            _customSetCategory[difficulty] != _selectedCategory) {
          // This custom set belongs to a different category; skip it.
          return;
        }
        if (_customSetMapping.containsKey(difficulty) &&
            _customSetImages.containsKey(difficulty)) {
          final imgs = _customSetImages[difficulty]!;
          for (var i = 0; i < imgs.length; i++) {
            final id = '$_selectedCategory-$difficulty-$i';
            final path = imgs[i];
            final w = SizedBox(
                width: 120,
                height: 120,
                child:
                    Center(child: Image.file(File(path), fit: BoxFit.contain)));
            visuals[id] = w;
          }
          return;
        }
        for (var i = 0; i < widgets.length; i++) {
          final id = '$_selectedCategory-$difficulty-$i';
          Widget w = widgets[i];
          if (difficulty == 'easy') {
            w = SizedBox(width: 120, height: 120, child: Center(child: w));
          } else if (difficulty == 'medium') {
            w = SizedBox(width: 90, height: 90, child: Center(child: w));
          } else {
            w = SizedBox(width: 64, height: 64, child: Center(child: w));
          }
          visuals[id] = w;
        }
      });
    }

    return GameExitGuard(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F6FF),
        appBar: _selectedCategory == null
            ? null
            : AppBar(
                leading: BackButton(onPressed: () async {
                  setState(() {
                    _selectedCategory = null;
                    _selectedDifficulty = null;
                  });
                  await _savePersistedCustomSets();
                }),
                title: const Text('Match the Pictures',
                    style: TextStyle(fontFamily: 'Nunito')),
                backgroundColor: Colors.green.shade300,
                elevation: 0,
                actions: [
                  IconButton(
                    tooltip: 'Attach images (add to custom set)',
                    icon: SizedBox(
                      width: 36,
                      height: 36,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.pink.shade50,
                            child: const Icon(
                              Icons.photo_library,
                              size: 18,
                              color: Colors.pink,
                            ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.green.shade400,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.add,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    onPressed: () async {
                      await _pickImagesForCurrentSet();
                    },
                  ),
                  IconButton(
                    tooltip: 'Reset progress',
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Reset progress?'),
                          content: const Text(
                              'This will clear your progress for this game mode.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Reset')),
                          ],
                        ),
                      );
                      if (!mounted) return;
                      if (confirmed == true) {
                        await _gameKey.currentState?.resetGame();
                        if (!mounted) return;
                        messenger?.showSnackBar(
                            const SnackBar(content: Text('Progress reset')));
                      }
                    },
                  ),
                ],
              ),
        body: Stack(
          children: [
            const Positioned.fill(child: AnimatedBubblesBackground()),
            if (_selectedCategory == null)
              Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: categories.map((cat) {
                      // Provide themed visuals per category
                      Widget visual;
                      Color color;
                      switch (cat) {
                        case 'Fruits':
                          color = Colors.orange.shade400;
                          visual = const Center(
                              child:
                                  Text('🍎', style: TextStyle(fontSize: 48)));
                          break;
                        case 'Vegetables':
                          color = Colors.green.shade500;
                          visual = const Center(
                              child:
                                  Text('🥕', style: TextStyle(fontSize: 48)));
                          break;
                        case 'Colors':
                          color = Colors.purple.shade400;
                          visual = Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Expanded(
                                  child: ColoredBox(
                                      color: Colors.red, child: SizedBox())),
                              SizedBox(width: 4),
                              Expanded(
                                  child: ColoredBox(
                                      color: Colors.green, child: SizedBox())),
                              SizedBox(width: 4),
                              Expanded(
                                  child: ColoredBox(
                                      color: Colors.blue, child: SizedBox())),
                            ],
                          );
                          break;
                        case 'Shapes':
                        default:
                          color = Colors.indigo.shade400;
                          visual = Center(
                              child: Icon(Icons.change_history,
                                  size: 48, color: Colors.white));
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _CategoryCard(
                          label: _displayLabel(cat),
                          color: color,
                          visual: visual,
                          onTap: () async {
                            if (_selectedCategory == cat) return;
                            setState(() {
                              _selectedCategory = cat;
                              // default to Set 1 (maps to 'easy')
                              _selectedDifficulty = 'set1';
                            });
                            await _savePersistedCustomSets();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              )
            else
              SizedBox.expand(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Top-level difficulty selector: small buttons placed at the very top
                    if (_selectedDifficulty == null)
                      SizedBox(
                        height: 180,
                        child: Center(
                          child: Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            alignment: WrapAlignment.center,
                            children: [
                              // Order: Set1, Set2, custom sets..., All
                              ...[
                                ...['set1', 'set2'],
                                ..._customSetMapping.keys.where((k) =>
                                    _customSetCategory[k] == null ||
                                    _customSetCategory[k] == _selectedCategory),
                                'all'
                              ].map((level) {
                                return GestureDetector(
                                  onTap: () async {
                                    setState(() {
                                      _selectedDifficulty = level;
                                    });
                                    await _savePersistedCustomSets();
                                    // MatchingGameBase will reload saved progress when
                                    // it notices the mode.progressKey has changed.
                                  },
                                  onLongPress: () {
                                    if (_customSetMapping.containsKey(level)) {
                                      _showCustomSetMenu(level);
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      color: _selectedDifficulty == level
                                          ? Colors.green.shade400
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 12)
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                          _labelForLevel(level).toUpperCase(),
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  _selectedDifficulty == level
                                                      ? Colors.white
                                                      : Colors.black)),
                                    ),
                                  ),
                                );
                              }).toList(),
                              // Add button tile: create the set then open the empty editor screen
                              GestureDetector(
                                onTap: () async {
                                  // create the custom set but don't select immediately
                                  final key =
                                      _createCustomSet(selectNow: false);
                                  // open the custom set image editor so user can add images
                                  await _openCustomSetEditor(key);
                                  // after returning, select the new set so it opens empty
                                  setState(() {
                                    _selectedDifficulty = key;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black12, blurRadius: 12)
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.add, size: 36),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: SizedBox(
                          height: 56,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ...[
                                  ...['set1', 'set2'],
                                  ..._customSetMapping.keys.where((k) =>
                                      _customSetCategory[k] == null ||
                                      _customSetCategory[k] ==
                                          _selectedCategory),
                                  'all'
                                ]
                                    .map((level) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6),
                                          child: GestureDetector(
                                            onTap: () async {
                                              if (_selectedDifficulty ==
                                                  level) {
                                                return;
                                              }
                                              setState(() {
                                                _selectedDifficulty = level;
                                              });
                                              await _savePersistedCustomSets();
                                              // Do not call resetGame here: that removes persisted
                                              // progress. MatchingGameBase.didUpdateWidget will
                                              // detect the changed progressKey/pairs and reload
                                              // progress automatically.
                                            },
                                            onLongPress: () {
                                              // only show menu for custom keys
                                              if (_customSetMapping
                                                  .containsKey(level)) {
                                                _showCustomSetMenu(level);
                                              }
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              constraints: const BoxConstraints(
                                                minWidth: 72,
                                                maxWidth: 140,
                                              ),
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color:
                                                    _selectedDifficulty == level
                                                        ? Colors.green.shade400
                                                        : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: const [
                                                  BoxShadow(
                                                      color: Colors.black12,
                                                      blurRadius: 8)
                                                ],
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12),
                                                child: Center(
                                                  child: Text(
                                                      _labelForLevel(level)
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight
                                                              .bold,
                                                          color:
                                                              _selectedDifficulty ==
                                                                      level
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                                // small add button
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: GestureDetector(
                                    onTap: () async {
                                      final key = _createCustomSet();
                                      // immediately open editor for this new set
                                      await _openCustomSetEditor(key);
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      constraints: const BoxConstraints(
                                        minWidth: 72,
                                        maxWidth: 140,
                                      ),
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: const [
                                          BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 8)
                                        ],
                                      ),
                                      child:
                                          const Center(child: Icon(Icons.add)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: !_prefsLoaded
                          ? const Center(child: CircularProgressIndicator())
                          : MatchingGameBase(
                              key: _gameKey,
                              showMatchedTray: false,
                              mode: MatchingPicturesMode(
                                pairs,
                                visuals,
                                // let mode suggest size by difficulty
                                _selectedDifficulty == 'set1'
                                    ? 140.0
                                    : _selectedDifficulty == 'set2'
                                        ? 96.0
                                        : 96.0,
                                // unique progress key per category and difficulty so toggling doesn't wipe visuals
                                '${_selectedCategory}_${_selectedDifficulty ?? 'all'}',
                                // preferred center gap: make more center space for fruits and shapes
                                (_selectedCategory == 'Fruits' ||
                                        _selectedCategory == 'Shapes' ||
                                        _selectedCategory == 'Vegetables')
                                    ? 160.0
                                    : null,
                              ),
                              title: '',
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
