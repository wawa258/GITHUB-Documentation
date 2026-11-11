import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/* ======================================================================
   CONFIG – match these to your sprite sheets
   ====================================================================== */
const String kSpritePath = 'assets/sprites/';
const int kFrame = 32; // px per frame
const int kIdleCol = 1; // middle column = standing
const List<int> kWalkCols = [1, 0, 1, 2];
const bool kWalkPreview = false; // true = preview walks in place
const int kBodyVariant = 0; // each outfit has 2 body blocks: 0 or 1
// Draw order, bottom -> top. Move "back" if it looks wrong.
const List<String> kLayerOrder = ['back', 'body', 'hair'];

const List<String> kDirs = [
  'down',
  'left',
  'right',
  'up',
]; // row order in a block

const skins = [
  ('Fair', Color(0xFFEEDAB3)),
  ('Tan', Color(0xFFE0AA76)),
  ('Brown', Color(0xFF986440)),
];
const lengths = ['Short', 'Medium', 'Long'];
const hairs = [
  ('Brown', Color(0xFF6E4226)),
  ('Golden', Color(0xFFC1A23C)),
  ('Pink', Color(0xFFE05E9E)),
];
const outfits = [
  ('Crimson', Color(0xFFD92B2B)),
  ('Azure', Color(0xFF0A60E1)),
  ('Green', Color(0xFF22C55E)),
];

/* block index -> first row (in frames) inside each sheet */
int bodyRow(int skin, int outfit) => (skin * 6 + outfit * 2 + kBodyVariant) * 4;
int hairRow(int len, int color) => (len * 3 + color) * 4;
int backRow(int color) => color * 4;

/* ======================================================================
   COLORS
   ====================================================================== */
const cGold = Color(0xFFFFC933);
const cGoldDk = Color(0xFFD98E04);
const cInk = Color(0xFF0D0620);
const cPanel = Color(0xFF150B34);
const cPreviewPanel = Color(0xFF24145C);
const cLine = Color(0xFF5A38C4);
const cLineHi = Color(0xFF8F6BFF);
const cLav = Color(0xFFD9CDFC);
const cLavDim = Color(0xFF9A8DD0);
const cBrown = Color(0xFF2A1608);

TextStyle px(double size, Color c, {double ls = 1}) =>
    GoogleFonts.pressStart2p(fontSize: size, color: c, letterSpacing: ls);
TextStyle inter(
  double size,
  Color c, {
  FontWeight w = FontWeight.w700,
  double ls = 1.5,
}) => GoogleFonts.inter(
  fontSize: size,
  color: c,
  fontWeight: w,
  letterSpacing: ls,
);

/* ======================================================================
   MODEL
   ====================================================================== */
class PlayerConfig {
  final String name;
  final int gender;
  final int skin, hairLength, hairColor, outfit;
  const PlayerConfig(
    this.name,
    this.gender,
    this.skin,
    this.hairLength,
    this.hairColor,
    this.outfit,
  );

  bool get male => gender == 0;

  Map<String, dynamic> toJson() => {
    'name': name,
    'gender': gender,
    'skin': skin,
    'hairLength': hairLength,
    'hairColor': hairColor,
    'outfit': outfit,
  };
}

/* ======================================================================
   SPRITE RENDERING (reusable in your game too)
   ====================================================================== */
class SheetSet {
  final ui.Image body, hair, back;
  SheetSet(this.body, this.hair, this.back);
  ui.Image of(String layer) =>
      layer == 'body' ? body : (layer == 'hair' ? hair : back);
}

Future<ui.Image> _loadImage(String path) async {
  final data = await rootBundle.load(path);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final codec = await ui.instantiateImageCodec(bytes);
  return (await codec.getNextFrame()).image;
}

Future<SheetSet> loadSheets(String g) async => SheetSet(
  await _loadImage('${kSpritePath}codenect_${g}_body.png'),
  await _loadImage('${kSpritePath}codenect_${g}_hair.png'),
  await _loadImage('${kSpritePath}codenect_${g}_back.png'),
);

class SpritePainter extends CustomPainter {
  final SheetSet sheets;
  final int skin, len, hair, outfit, dir, col;
  SpritePainter(
    this.sheets,
    this.skin,
    this.len,
    this.hair,
    this.outfit,
    this.dir,
    this.col,
  );

  int _row(String layer) => switch (layer) {
    'body' => bodyRow(skin, outfit),
    'hair' => hairRow(len, hair),
    _ => backRow(hair),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.none; // crisp pixels
    final dst = Offset.zero & size;
    for (final layer in kLayerOrder) {
      final row = _row(layer) + dir;
      final src = Rect.fromLTWH(
        (col * kFrame).toDouble(),
        (row * kFrame).toDouble(),
        kFrame.toDouble(),
        kFrame.toDouble(),
      );
      canvas.drawImageRect(sheets.of(layer), src, dst, paint);
    }
  }

  @override
  bool shouldRepaint(SpritePainter o) =>
      o.sheets != sheets ||
      o.skin != skin ||
      o.len != len ||
      o.hair != hair ||
      o.outfit != outfit ||
      o.dir != dir ||
      o.col != col;
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cLineHi.withValues(alpha: .14)
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

/* ======================================================================
   SCREEN  (designed on a 1280x720 stage, scaled to fit)
   ====================================================================== */
class CreatePlayerScreen extends StatefulWidget {
  final void Function(PlayerConfig player) onStart;
  final VoidCallback? onBack;
  const CreatePlayerScreen({super.key, required this.onStart, this.onBack});

  @override
  State<CreatePlayerScreen> createState() => _CreatePlayerScreenState();
}

class _CreatePlayerScreenState extends State<CreatePlayerScreen> {
  SheetSet? _male, _female;
  Object? _sheetLoadError;
  bool male = true;
  int skin = 0, len = 1, hair = 1, outfit = 1, dir = 0, col = kIdleCol;
  final _name = TextEditingController();
  String? _error;
  Timer? _walk;
  int _walkStep = 0;

  @override
  void initState() {
    super.initState();
    _loadSheets();
    if (kWalkPreview) {
      _walk = Timer.periodic(const Duration(milliseconds: 180), (_) {
        _walkStep = (_walkStep + 1) % kWalkCols.length;
        setState(() => col = kWalkCols[_walkStep]);
      });
    }
  }

  Future<void> _loadSheets() async {
    try {
      final sheets = await Future.wait([loadSheets('m'), loadSheets('f')]);
      if (!mounted) return;
      setState(() {
        _male = sheets[0];
        _female = sheets[1];
      });
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'CreatePlayerScreen sprite loading',
        ),
      );
      if (!mounted) return;
      setState(() => _sheetLoadError = error);
    }
  }

  @override
  void dispose() {
    _walk?.cancel();
    _name.dispose();
    super.dispose();
  }

  SheetSet get _sheets => male ? _male! : _female!;

  void _start() {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Pick a name first!');
      return;
    }
    widget.onStart(
      PlayerConfig(_name.text.trim(), male ? 0 : 1, skin, len, hair, outfit),
    );
  }

  void _back() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Widget _sprite(double scale, int d, int c) => SizedBox(
    width: kFrame * scale,
    height: kFrame * scale,
    child: CustomPaint(
      painter: SpritePainter(_sheets, skin, len, hair, outfit, d, c),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ready = _male != null && _female != null;
    return Scaffold(
      backgroundColor: const Color(0xFF07031A),
      body: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 1280,
            height: 720,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 0.75,
                  colors: [
                    Color(0xFF4B2A9C),
                    Color(0xFF1F1052),
                    Color(0xFF0D0620),
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const CustomPaint(painter: _GridPainter()),
                  if (_sheetLoadError case final error?)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Unable to load player sprites.\n$error',
                          textAlign: TextAlign.center,
                          style: inter(14, Colors.white),
                        ),
                      ),
                    )
                  else if (ready)
                    _content()
                  else
                    const Center(
                      child: CircularProgressIndicator(color: cGold),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    return Stack(
      children: [
        Positioned(
          left: 584,
          top: 104,
          width: 636,
          height: 526,
          child: Image.asset(
            'assets/images/create-form for chreate player character.png',
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
          ),
        ),
        // ---------- left: preview panel ----------
        Positioned(
          left: 60,
          top: 56,
          width: 478,
          height: 608,
          child: _previewPanel(),
        ),

        // ---------- right: form ----------
        Positioned(
          right: 64,
          top: 112,
          child: Text('STEP 1 / 2', style: px(11, cLav)),
        ),

        Positioned(
          left: 590,
          top: 154,
          child: Text('CHARACTER NAME', style: inter(12, cGold)),
        ),
        Positioned(
          left: 590,
          top: 178,
          width: 626,
          height: 52,
          child: TextField(
            controller: _name,
            style: inter(16, Colors.white, w: FontWeight.w500, ls: 0),
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: inter(16, cLavDim, w: FontWeight.w500, ls: 0),
              filled: true,
              fillColor: cPanel,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: cLine, width: 3),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: cGold, width: 3),
              ),
            ),
          ),
        ),
        if (_error != null)
          Positioned(
            left: 590,
            top: 232,
            child: Text(
              _error!,
              style: inter(12, const Color(0xFFFF7A7A), ls: 0),
            ),
          ),

        Positioned(
          left: 590,
          top: 251,
          child: Text('CHARACTER TYPE', style: inter(12, cGold)),
        ),
        Positioned(
          left: 590,
          top: 275,
          width: 305,
          height: 52,
          child: _OptButton(
            'MALE',
            selected: male,
            size: 13,
            onTap: () => setState(() => male = true),
          ),
        ),
        Positioned(
          left: 911,
          top: 275,
          width: 305,
          height: 52,
          child: _OptButton(
            'FEMALE',
            selected: !male,
            size: 13,
            onTap: () => setState(() => male = false),
          ),
        ),

        // skin + hair length
        Positioned(
          left: 590,
          top: 348,
          child: Text('SKIN TONE', style: inter(12, cGold)),
        ),
        Positioned(
          left: 790,
          top: 348,
          width: 97,
          height: 18,
          child: Container(
            color: Colors.black,
            alignment: Alignment.centerRight,
            child: Text(skins[skin].$1, style: inter(12, cLav)),
          ),
        ),
        Positioned(
          left: 590,
          top: 372,
          width: 297,
          height: 56,
          child: _swatchRow(
            skins.map((e) => e.$2).toList(),
            skin,
            (i) => setState(() => skin = i),
          ),
        ),

        Positioned(
          left: 919,
          top: 348,
          child: Text('HAIR LENGTH', style: inter(12, cGold)),
        ),
        Positioned(
          left: 1116,
          top: 348,
          width: 100,
          height: 18,
          child: Container(
            color: Colors.black,
            alignment: Alignment.centerRight,
            child: Text(lengths[len], style: inter(12, cLav)),
          ),
        ),
        Positioned(
          left: 919,
          top: 372,
          width: 297,
          height: 56,
          child: _lengthRow(),
        ),

        // hair color + outfit
        Positioned(
          left: 590,
          top: 445,
          child: Text('HAIR COLOR', style: inter(12, cGold)),
        ),
        Positioned(
          left: 790,
          top: 445,
          width: 97,
          height: 18,
          child: Container(
            color: Colors.black,
            alignment: Alignment.centerRight,
            child: Text(hairs[hair].$1, style: inter(12, cLav)),
          ),
        ),
        Positioned(
          left: 590,
          top: 469,
          width: 297,
          height: 56,
          child: _swatchRow(
            hairs.map((e) => e.$2).toList(),
            hair,
            (i) => setState(() => hair = i),
          ),
        ),

        Positioned(
          left: 919,
          top: 445,
          child: Text('OUTFIT COLOR', style: inter(12, cGold)),
        ),
        Positioned(
          left: 1116,
          top: 445,
          width: 100,
          height: 18,
          child: Container(
            color: Colors.black,
            alignment: Alignment.centerRight,
            child: Text(outfits[outfit].$1, style: inter(12, cLav)),
          ),
        ),
        Positioned(
          left: 919,
          top: 469,
          width: 297,
          height: 56,
          child: _swatchRow(
            outfits.map((e) => e.$2).toList(),
            outfit,
            (i) => setState(() => outfit = i),
          ),
        ),

        // buttons
        Positioned(
          left: 590,
          top: 555,
          width: 150,
          height: 64,
          child: _OptButton('BACK', selected: false, size: 14, onTap: _back),
        ),
        Positioned(
          left: 760,
          top: 555,
          width: 456,
          height: 64,
          child: _OptButton(
            'START ADVENTURE',
            selected: true,
            size: 17,
            letterSpacing: 2,
            onTap: _start,
          ),
        ),
      ],
    );
  }

  Widget _previewPanel() {
    final name = _name.text.trim().isEmpty
        ? 'PLAYER ONE'
        : _name.text.trim().toUpperCase();
    const scaleX = 478 / 614;
    const scaleY = 608 / 720;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/preview-panel for create player character.png',
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
          ),
        ),
        Positioned(
          left: 98 * scaleX,
          top: 124 * scaleY,
          width: 402 * scaleX,
          height: 348 * scaleY,
          child: ClipRect(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 0.75,
                  colors: [
                    Color(0xFF4B2A9C),
                    Color(0xFF1F1052),
                    Color(0xFF0D0620),
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Positioned(
                    left: 30,
                    top: 28,
                    child: SizedBox(
                      width: 8,
                      height: 8,
                      child: ColoredBox(color: cGold),
                    ),
                  ),
                  const Positioned(
                    right: 42,
                    top: 56,
                    child: SizedBox(
                      width: 6,
                      height: 6,
                      child: ColoredBox(color: Colors.white),
                    ),
                  ),
                  const Positioned(
                    left: 64,
                    bottom: 72,
                    child: SizedBox(
                      width: 6,
                      height: 6,
                      child: ColoredBox(color: cLineHi),
                    ),
                  ),
                  const Positioned(
                    right: 34,
                    bottom: 54,
                    child: SizedBox(
                      width: 8,
                      height: 8,
                      child: ColoredBox(color: cGold),
                    ),
                  ),
                  Center(child: _sprite(10, dir, col)),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 86 * scaleX,
          top: 488 * scaleY,
          width: 420 * scaleX,
          height: 112 * scaleY,
          child: DecoratedBox(
            decoration: const BoxDecoration(color: cPreviewPanel),
          ),
        ),
        Positioned(
          left: 86 * scaleX,
          top: 491 * scaleY,
          width: 420 * scaleX,
          height: 106 * scaleY,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < 4; i++)
                GestureDetector(
                  onTap: () => setState(() => dir = i),
                  child: Container(
                    width: 88.5 * scaleX,
                    height: 100 * scaleY,
                    decoration: BoxDecoration(
                      color: cPanel,
                      border: Border.all(
                        color: dir == i ? cGold : cLine,
                        width: dir == i ? 4 : 3,
                      ),
                      boxShadow: dir == i
                          ? const [BoxShadow(color: cInk, spreadRadius: 2)]
                          : null,
                    ),
                    child: Center(child: _sprite(2.2, i, kIdleCol)),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          left: 164 * scaleX,
          top: 604 * scaleY,
          width: 280 * scaleX,
          height: 42 * scaleY,
          child: ColoredBox(color: cPreviewPanel),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 608 * scaleY,
          child: Text(name, textAlign: TextAlign.center, style: px(18, cGold)),
        ),
      ],
    );
  }

  Widget _swatchRow(
    List<Color> colors,
    int selected,
    ValueChanged<int> onPick,
  ) => Row(
    children: [
      for (int i = 0; i < colors.length; i++) ...[
        if (i > 0) const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => onPick(i),
            child: Container(
              decoration: BoxDecoration(
                color: colors[i],
                border: Border.all(
                  color: selected == i ? cGold : cLine,
                  width: 3,
                ),
                boxShadow: selected == i
                    ? const [
                        BoxShadow(color: cInk, spreadRadius: 3),
                        BoxShadow(color: cGold, spreadRadius: 6),
                      ]
                    : null,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: .25),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: .22),
                    ],
                    stops: const [0, .16, .84, 1],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );

  Widget _lengthRow() => Row(
    children: [
      for (int i = 0; i < lengths.length; i++) ...[
        if (i > 0) const SizedBox(width: 12),
        Expanded(
          child: _OptButton(
            lengths[i].toUpperCase(),
            selected: len == i,
            size: 10,
            onTap: () => setState(() => len = i),
          ),
        ),
      ],
    ],
  );
}

/* ======================================================================
   PIXEL BUTTON
   ====================================================================== */
class _OptButton extends StatelessWidget {
  final String text;
  final bool selected;
  final double size;
  final double letterSpacing;
  final VoidCallback onTap;
  const _OptButton(
    this.text, {
    required this.selected,
    required this.size,
    this.letterSpacing = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? cGold : cPanel,
        border: Border.all(color: selected ? cGold : cLine, width: 3),
        boxShadow: selected
            ? const [BoxShadow(color: cGoldDk, offset: Offset(0, 4))]
            : null,
      ),
      child: Text(
        text,
        style: px(size, selected ? cBrown : Colors.white, ls: letterSpacing),
      ),
    ),
  );
}
