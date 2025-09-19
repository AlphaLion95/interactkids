// --- PUZZLE MODULE: GAMIFIED UI RESTORE ---



/// Full puzzle module with fixes:
/// - initializes missing fields
/// - supports asset and file images
/// - drag & drop between tray and board
/// - reset, win detection, and win dialog
/// - pass rows/cols from level screen

class PuzzleScreen extends StatefulWidget {
  final String? imagePath;
  final int rows;
  final int cols;
  const PuzzleScreen({
    Key? key,
    this.imagePath,
    this.rows = 3,
    this.cols = 3,
  }) : super(key: key);

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force landscape orientation when this screen is shown
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Restore orientation to allow both portrait and landscape when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }
  double? _imageAspectRatio;
  late ImageProvider _imageProvider;
  late int rows;
  late int cols;

  // pieceOrder: indices of pieces currently in the tray (available pieces)
  late List<int> pieceOrder;

  // boardState: length rows*cols, each entry is either an int piece index or null
  late List<int?> boardState;

  int? draggingIndex;
  bool hasWon = false;

  @override
  void initState() {
    super.initState();
    rows = widget.rows;
    cols = widget.cols;

    // prepare image provider (asset or file)
    if (widget.imagePath == null) {
      _imageProvider = const AssetImage('assets/puzzle/default.png');
    } else {
      final path = widget.imagePath!;
      if (path.startsWith('assets/')) {
        _imageProvider = AssetImage(path);
      } else {
        _imageProvider = FileImage(File(path));
      }
    }

    _getImageAspectRatio();
    _resetGame();
  }

  void _getImageAspectRatio() async {
    final ImageStream stream = _imageProvider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener((ImageInfo info, bool _) {
      final width = info.image.width;
      final height = info.image.height;
      setState(() {
        _imageAspectRatio = width / height;
      });
      stream.removeListener(listener);
    });
    stream.addListener(listener);
  }

  void _resetGame() {
    pieceOrder = List.generate(rows * cols, (i) => i)..shuffle();
    boardState = List.filled(rows * cols, null);
    draggingIndex = null;
    hasWon = false;
  }

  bool _isSolved() {
    for (int i = 0; i < boardState.length; i++) {
      if (boardState[i] != i) return false;
    }
    return true;
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("You Win!"),
        content: const Text("Great job — puzzle complete."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Close"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _resetGame());
            },
            child: const Text("Play again"),
          ),
        ],
      ),
    );
  }

  /// Called when a piece is dropped onto board index [boardIdx] with piece index [pieceIdx]
  void _onPieceDroppedToBoard(int boardIdx, int pieceIdx) {
    setState(() {
      // remove piece from tray if present
      if (pieceOrder.contains(pieceIdx)) {
        pieceOrder.remove(pieceIdx);
      } else {
        // if it's coming from another board cell, clear that cell
        final prev = boardState.indexOf(pieceIdx);
        if (prev != -1) boardState[prev] = null;
      }

      // place on board
      boardState[boardIdx] = pieceIdx;
      draggingIndex = null;

      if (_isSolved()) {
        hasWon = true;
        // delay to allow UI update of final piece before dialog
        Future.delayed(const Duration(milliseconds: 150), () => _showWinDialog());
      }
    });
  }

  /// Called when a placed piece is removed (double tap) from board index [boardIdx]
  void _onPieceRemovedFromBoard(int boardIdx) {
    setState(() {
      final pieceIdx = boardState[boardIdx];
      if (pieceIdx != null) {
        boardState[boardIdx] = null;
        if (!pieceOrder.contains(pieceIdx)) {
          pieceOrder.add(pieceIdx);
        }
      }
    });
  }

  /// Put the UI together: faded guide image behind, board in center, tray at bottom and reset button
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puzzle', style: TextStyle(fontFamily: 'Nunito')),
        backgroundColor: Colors.orange,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final double trayHeight = 120;
            final double availableHeight = constraints.maxHeight - trayHeight;
            return isLandscape
                ? Row(
                    children: [
                      // Puzzle board area (left, takes most space)
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 500, // limit board width
                              maxHeight: 500, // optional: also limit height
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: _imageAspectRatio == null
                                  ? const Center(child: CircularProgressIndicator())
                                  : AspectRatio(
                                      aspectRatio: _imageAspectRatio!,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Stack(
                                          children: [
                                            // guide image slightly brightened underneath
                                            LayoutBuilder(
                                              builder: (context, constraints) {
                                                final boardW = constraints.maxWidth;
                                                final boardH = constraints.maxHeight;
                                                final imgAR = _imageAspectRatio ?? 1.0;
                                                double imgW = boardW;
                                                double imgH = boardH;
                                                double offsetX = 0;
                                                double offsetY = 0;
                                                if (boardW / boardH > imgAR) {
                                                  // board is wider than image: letterbox left/right
                                                  imgH = boardH;
                                                  imgW = imgH * imgAR;
                                                  offsetX = (boardW - imgW) / 2;
                                                } else {
                                                  // board is taller than image: letterbox top/bottom
                                                  imgW = boardW;
                                                  imgH = imgW / imgAR;
                                                  offsetY = (boardH - imgH) / 2;
                                                }
                                                return Stack(
                                                  children: [
                                                    // Guide image
                                                    Positioned(
                                                      left: offsetX,
                                                      top: offsetY,
                                                      width: imgW,
                                                      height: imgH,
                                                      child: Opacity(
                                                        opacity: 0.7,
                                                        child: Image(
                                                          image: _imageProvider,
                                                          fit: BoxFit.fill,
                                                        ),
                                                      ),
                                                    ),
                                                    // Puzzle board overlay, perfectly aligned
                                                    Positioned(
                                                      left: offsetX,
                                                      top: offsetY,
                                                      width: imgW,
                                                      height: imgH,
                                                      child: _PuzzleBoardWithTray(
                                                        imageProvider: _imageProvider,
                                                        rows: rows,
                                                        cols: cols,
                                                        boardState: boardState,
                                                        draggingIndex: draggingIndex,
                                                        onPieceDropped: _onPieceDroppedToBoard,
                                                        onPieceRemoved: _onPieceRemovedFromBoard,
                                                        trayPieces: pieceOrder,
                                                        onStartDraggingFromTray: (index) {
                                                          setState(() {
                                                            draggingIndex = index;
                                                          });
                                                        },
                                                        onEndDragging: () {
                                                          setState(() {
                                                            draggingIndex = null;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      // Tray area (right, vertical)
                      Container(
                        width: 180,
                        color: Colors.grey.withOpacity(0.04),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                              child: Row(
                                children: [
                                  Text('${rows}x$cols Puzzle', style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.refresh, color: Colors.orange),
                                    onPressed: () => setState(() => _resetGame()),
                                    tooltip: 'Reset',
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Pieces', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: SizedBox.expand(
                                child: ListView.separated(
                                  scrollDirection: Axis.vertical,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  itemBuilder: (context, index) {
                                    final pieceIdx = pieceOrder[index];
                                    return Draggable<int>(
                                      data: pieceIdx,
                                      feedback: Material(
                                        color: Colors.transparent,
                                        child: SizedBox(
                                          width: 88,
                                          height: 88,
                                          child: _PuzzlePiece(
                                            imageProvider: _imageProvider,
                                            rows: rows,
                                            cols: cols,
                                            row: pieceIdx ~/ cols,
                                            col: pieceIdx % cols,
                                          ),
                                        ),
                                      ),
                                      childWhenDragging: Opacity(opacity: 0.25, child: _trayPieceWidget(_imageProvider, pieceIdx)),
                                      onDragStarted: () => setState(() => draggingIndex = pieceIdx),
                                      onDraggableCanceled: (_, __) => setState(() => draggingIndex = null),
                                      onDragEnd: (_) => setState(() => draggingIndex = null),
                                      child: _trayPieceWidget(_imageProvider, pieceIdx),
                                    );
                                  },
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemCount: pieceOrder.length,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const Center(child: Text('Please rotate your device to landscape for the best puzzle experience.'));
          },
        ),
      ),
    );
  }

  Widget _trayPieceWidget(ImageProvider provider, int pieceIdx) {
    // Use the same aspect ratio as a board tile
    final double tileAspect = (cols > 0 && rows > 0) ? (_imageAspectRatio ?? 1.0) * rows / cols : 1.0;
    // Use a fixed tray piece height, width from aspect
    const double trayPieceHeight = 40; // smaller, more natural size
    final double trayPieceWidth = trayPieceHeight * tileAspect;
    return AspectRatio(
      aspectRatio: tileAspect,
      child: Container(
        width: trayPieceWidth,
        height: trayPieceHeight,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: trayPieceWidth,
              height: trayPieceHeight,
              child: _PuzzlePiece(
                imageProvider: provider,
                rows: rows,
                cols: cols,
                row: pieceIdx ~/ cols,
                col: pieceIdx % cols,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PuzzleBoardWithTray extends StatelessWidget {
  final ImageProvider imageProvider;
  final int rows;
  final int cols;
  final List<int?> boardState;
  final List<int>? trayPieces; // indices remaining in tray
  final int? draggingIndex;
  final void Function(int boardIdx, int pieceIdx)? onPieceDropped;
  final void Function(int boardIdx)? onPieceRemoved;
  final void Function(int pieceIdx)? onStartDraggingFromTray;
  final VoidCallback? onEndDragging;

  const _PuzzleBoardWithTray({
    Key? key,
    required this.imageProvider,
    required this.rows,
    required this.cols,
    required this.boardState,
    this.trayPieces,
    this.draggingIndex,
    this.onPieceDropped,
    this.onPieceRemoved,
    this.onStartDraggingFromTray,
    this.onEndDragging,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // build a grid of stack positioned DragTargets and placed Draggables
    return LayoutBuilder(builder: (context, constraints) {
      final double tileWidth = constraints.maxWidth / cols;
      final double tileHeight = constraints.maxHeight / rows;

      final children = <Widget>[];

      for (int index = 0; index < rows * cols; index++) {
        final int row = index ~/ cols;
        final int col = index % cols;
        final int? pieceIdx = boardState[index];

        children.add(Positioned(
          left: col * tileWidth,
          top: row * tileHeight,
          width: tileWidth,
          height: tileHeight,
          child: DragTarget<int>(
            onWillAccept: (data) => pieceIdx == null, // accept only when empty
            onAccept: (data) {
              if (onPieceDropped != null) onPieceDropped!(index, data);
            },
            builder: (context, candidateData, rejectedData) {
              if (pieceIdx != null) {
                // placed piece: make it draggable so it can be moved to other slots or removed
                return Draggable<int>(
                  data: pieceIdx,
                  feedback: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      width: tileWidth,
                      height: tileHeight,
                      child: _PuzzlePiece(
                        imageProvider: imageProvider,
                        rows: rows,
                        cols: cols,
                        row: pieceIdx ~/ cols,
                        col: pieceIdx % cols,
                      ),
                    ),
                  ),
                  childWhenDragging: Container(
                    width: tileWidth,
                    height: tileHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                  onDragStarted: () {
                    // nothing special here
                  },
                  onDragEnd: (details) {
                    if (onEndDragging != null) onEndDragging!();
                  },
                  child: GestureDetector(
                    onDoubleTap: () {
                      if (onPieceRemoved != null) onPieceRemoved!(index);
                    },
                    child: Container(
                      width: tileWidth,
                      height: tileHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white.withOpacity(0.12),
                      ),
                      child: _PuzzlePiece(
                        imageProvider: imageProvider,
                        rows: rows,
                        cols: cols,
                        row: pieceIdx ~/ cols,
                        col: pieceIdx % cols,
                      ),
                    ),
                  ),
                );
              } else {
                // empty slot: show placeholder
                return Container(
                  width: tileWidth,
                  height: tileHeight,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white.withOpacity(0.02),
                  ),
                  child: candidateData.isNotEmpty
                      ? Center(child: Opacity(opacity: 0.6, child: Icon(Icons.open_in_new, size: 28, color: Colors.orange)))
                      : null,
                );
              }
            },
          ),
        ));
      }

      return Stack(children: children);
    });
  }
}

class _PuzzlePiece extends StatelessWidget {
  final ImageProvider imageProvider;
  final int rows;
  final int cols;
  final int row;
  final int col;
  final bool miniature; // true for tray pieces
  const _PuzzlePiece({
    Key? key,
    required this.imageProvider,
    required this.rows,
    required this.cols,
    required this.row,
    required this.col,
    this.miniature = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double tileWidth = constraints.maxWidth;
        final double tileHeight = constraints.maxHeight;
        if (!miniature) {
          // Board: render full image, shift to show only tile area
          return Stack(
            children: [
              Positioned(
                left: -col * tileWidth,
                top: -row * tileHeight,
                child: Image(
                  image: imageProvider,
                  fit: BoxFit.cover,
                  width: tileWidth * cols,
                  height: tileHeight * rows,
                ),
              ),
              ClipRect(
                child: SizedBox(width: tileWidth, height: tileHeight),
              ),
            ],
          );
        } else {
          // Tray: render the full image scaled down, but only show the tile region
          return FractionallySizedBox(
            widthFactor: 1 / cols,
            heightFactor: 1 / rows,
            alignment: Alignment(
              -1.0 + 2.0 * col / (cols - 1 == 0 ? 1 : cols - 1),
              -1.0 + 2.0 * row / (rows - 1 == 0 ? 1 : rows - 1),
            ),
            child: Image(
              image: imageProvider,
              fit: BoxFit.contain,
            ),
          );
        }
      },
    );
  }
}

/* --------------------------
   Rest of the screens & helpers
   -------------------------- */

class _PuzzleTheme {
  final String name;
  final IconData icon;
  final Color color;
  const _PuzzleTheme(this.name, this.icon, this.color);
}

class AnimatedBubbles extends StatefulWidget {
  const AnimatedBubbles({super.key});

  @override
  State<AnimatedBubbles> createState() => _AnimatedBubblesState();
}

class _AnimatedBubblesState extends State<AnimatedBubbles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Bubble> _bubbles = List.generate(18, (i) => _Bubble.random());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BubblesPainter(_bubbles, _controller.value),
        );
      },
    );
  }
}

class _Bubble {
  final double x, radius, speed, phase;
  final Color color;
  _Bubble(this.x, this.radius, this.speed, this.phase, this.color);
  static _Bubble random() {
    final colors = [Colors.orange, Colors.blue, Colors.purple, Colors.green, Colors.pink, Colors.yellow];
    return _Bubble(
      math.Random().nextDouble(),
      10 + math.Random().nextDouble() * 18,
      0.08 + math.Random().nextDouble() * 0.12,
      math.Random().nextDouble(),
      colors[math.Random().nextInt(colors.length)],
    );
  }
}

class _BubblesPainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double t;
  _BubblesPainter(this.bubbles, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final y = size.height * ((b.speed * t + b.phase) % 1.0);
      final x = size.width * b.x;
      final paint = Paint()..color = b.color.withOpacity(0.18);
      canvas.drawCircle(Offset(x, y), b.radius, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


/* Puzzle selection screens (Type -> Level -> Play) */

