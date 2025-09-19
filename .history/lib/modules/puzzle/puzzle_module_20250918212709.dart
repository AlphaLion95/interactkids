// Puzzle module entry
import 'package:flutter/material.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  String selectedTheme = 'Zoo';
  final List<_PuzzleTheme> themes = const [
    _PuzzleTheme('Zoo', Icons.pets, Color(0xFFffb347)),
    _PuzzleTheme('Sea', Icons.waves, Color(0xFF40c4ff)),
    _PuzzleTheme('Jungle', Icons.park, Color(0xFF66bb6a)),
  ];
  final List<String> levels = ['Level 1', 'Level 2', 'Level 3'];
  String? selectedLevel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Puzzle')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text('Choose a Theme:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Nunito')),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: themes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 24),
                itemBuilder: (context, i) {
                  final t = themes[i];
                  final isSelected = selectedTheme == t.name;
                  return AnimatedScale(
                    scale: isSelected ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        selectedTheme = t.name;
                        selectedLevel = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? t.color : t.color.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: t.color.withOpacity(0.4),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                          ],
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 4,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(t.icon, size: 48, color: Colors.white),
                            const SizedBox(height: 12),
                            Text(t.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Nunito', color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            Text('Select Level:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Nunito')),
            const SizedBox(height: 12),
            Row(
              children: levels.map((level) {
                final isSelected = selectedLevel == level;
                return Padding(
                  padding: const EdgeInsets.only(right: 18.0),
                  child: ElevatedButton(
                    onPressed: () => setState(() => selectedLevel = level),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.orange : Colors.grey.shade300,
                      foregroundColor: isSelected ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      textStyle: const TextStyle(fontSize: 18, fontFamily: 'Nunito'),
                    ),
                    child: Text(level),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            if (selectedLevel != null)
              Expanded(
                child: Center(
                  child: Text(
                    'Puzzle for $selectedTheme - $selectedLevel\n(Coming Soon!)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontFamily: 'Nunito', color: Colors.orange),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PuzzleTheme {
  final String name;
  final IconData icon;
  final Color color;
  const _PuzzleTheme(this.name, this.icon, this.color);
}
