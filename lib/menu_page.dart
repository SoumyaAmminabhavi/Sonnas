import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────

class _Tier {
  final String weight;
  final String serves;
  final String price;
  const _Tier(this.weight, this.serves, this.price);
}

class _Cake {
  final String name;
  final String flavours;
  final String description;
  final List<_Tier> tiers;
  const _Cake({
    required this.name,
    required this.flavours,
    required this.description,
    required this.tiers,
  });
}

class _Section {
  final String category;
  final List<_Cake> cakes;
  const _Section(this.category, this.cakes);
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu Data  (extracted from Sonna's printed menu)
// ─────────────────────────────────────────────────────────────────────────────

const List<_Tier> _std = [
  _Tier('600 grams', 'Serves 4–6', '750/-'),
  _Tier('1050 grams', 'Serves 8–12', '1350/-'),
];

final List<_Section> _menu = const [
  _Section('Chocolate Based', [
    _Cake(
      name: "SONNA'S CLASSIC CHOCOLATE",
      flavours: 'Chocolate cake  |  Chocolate Whipped Ganache',
      description: 'Classic chocolate cake with chocolate whipped ganache',
      tiers: [_Tier('600 grams', 'Serves 4–6', '675/-'), _Tier('1050 grams', 'Serves 8–12', '1250/-')],
    ),
    _Cake(
      name: 'ALMOND BRITTLE WITH SALTED CARAMEL GANACHE',
      flavours: 'Caramel  |  Caramel Chocolate Ganache  |  Almond Brittle',
      description: "A Sonna's original: In house caramel with caramel chocolate ganache with almond brittle",
      tiers: _std,
    ),
    _Cake(
      name: 'ORANGE & CHOCOLATE',
      flavours: 'Chocolate  |  Orange',
      description: 'Classic chocolate cake with orange chocolate whipped ganache',
      tiers: _std,
    ),
    _Cake(
      name: 'HAZELNUT & CHOCOLATE',
      flavours: 'Chocolate  |  Hazelnut',
      description: 'Chocolate cake with hazelnut ganache (chopped almonds optional)',
      tiers: _std,
    ),
    _Cake(
      name: 'COFFEE & CHOCOLATE',
      flavours: 'Chocolate  |  Coffee',
      description: 'Chocolate cake with coffee chocolate whipped ganache',
      tiers: _std,
    ),
  ]),
  _Section('Vanilla Based', [
    _Cake(
      name: 'CARAMALISED WHITE CHOCOLATE WITH ALMONDS',
      flavours: 'Caramalised white chocolate  |  Almond brittle  |  Vanilla',
      description: 'Vanilla cake with carmalised white chocolate ganache, almonds are optional',
      tiers: _std,
    ),
    _Cake(
      name: 'PINEAPPLE',
      flavours: 'Pineapple  |  Vanilla',
      description: 'Pineapple compote whipped ganache, vanilla cake',
      tiers: _std,
    ),
    _Cake(
      name: 'PINA COLADA',
      flavours: 'Pineapple  |  Coconut',
      description: 'Coconut & pineapple mousse, fresh pineapple',
      tiers: _std,
    ),
  ]),
  _Section('Tea Time', [
    _Cake(
      name: 'RICH MAWA',
      flavours: 'Mawa  |  Almond flour',
      description: 'Indian inspired mawa cake made with almond flour, all purpose flour, cardamom & butter',
      tiers: _std,
    ),
    _Cake(
      name: 'PERSIAN CAKE',
      flavours: 'Almond  |  Orange',
      description: 'Almond flour, orange juice, mawa, all purpose flour',
      tiers: _std,
    ),
    _Cake(
      name: 'BUTTER CAKE',
      flavours: 'Classic butter cake',
      description: 'Butter, butter and lots of love',
      tiers: _std,
    ),
  ]),
  _Section('Seasonal', [
    _Cake(
      name: 'STRAWBERRY & CHOCOLATE',
      flavours: 'Strawberry  |  Chocolate',
      description: 'Strawberry compote, chocolate ganache, fresh strawberries',
      tiers: _std,
    ),
    _Cake(
      name: 'STRAWBERRY & VANILLA',
      flavours: 'Strawberry  |  Vanilla',
      description: 'Vanilla cake, strawberry whipped ganache, fresh strawberries',
      tiers: _std,
    ),
  ]),
];

// ─────────────────────────────────────────────────────────────────────────────
// Wavy Decorator Painter  (matches the printed menu squiggle)
// ─────────────────────────────────────────────────────────────────────────────

class _WavyPainter extends CustomPainter {
  final Color color;
  const _WavyPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const w = 5.0;
    const h = 2.0;
    path.moveTo(0, size.height / 2);
    for (double x = 0; x < size.width; x += w * 2) {
      path.relativeQuadraticBezierTo(w / 2, -h, w, 0);
      path.relativeQuadraticBezierTo(w / 2, h, w, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavyPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// MenuPage  (StatefulWidget for tab state)
// ─────────────────────────────────────────────────────────────────────────────

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _selected = 0; // 0 = All

  List<_Section> get _visible =>
      _selected == 0 ? _menu : [_menu[_selected - 1]];

  String get _subtitle => _selected == 0
      ? '(Full Menu)'
      : '(${_menu[_selected - 1].category})';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const cream = Color(0xFFFFF8F5);
    const cocoa = Color(0xFF5C3317);

    return Scaffold(
      backgroundColor: cream,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: cream.withOpacity(0.96),
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.menu, color: cs.secondary),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            title: Text(
              "Sonna's Patisserie",
              style: GoogleFonts.notoSerif(
                color: cs.primary,
                fontStyle: FontStyle.italic,
                fontSize: 22,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.shopping_bag_outlined, color: cs.secondary),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ── Page Header + Category Tabs ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 44, 28, 0),
              child: Column(
                children: [
                  // Title Row: "Cakes (Subtitle)"
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Cakes',
                        style: GoogleFonts.notoSerif(
                          fontSize: 48,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                          color: cocoa,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _subtitle,
                        style: GoogleFonts.notoSerif(
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                          color: cocoa.withOpacity(0.5),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(width: 56, height: 1, color: cs.primary.withOpacity(0.35)),
                  const SizedBox(height: 28),

                  // Category Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _Tab(label: 'All', index: 0, selected: _selected, onTap: _setTab, cs: cs),
                        _Tab(label: 'Chocolate', index: 1, selected: _selected, onTap: _setTab, cs: cs),
                        _Tab(label: 'Vanilla', index: 2, selected: _selected, onTap: _setTab, cs: cs),
                        _Tab(label: 'Tea Time', index: 3, selected: _selected, onTap: _setTab, cs: cs),
                        _Tab(label: 'Seasonal', index: 4, selected: _selected, onTap: _setTab, cs: cs),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Menu Sections ──────────────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _SectionWidget(
                section: _visible[i],
                cs: cs,
                cocoa: cocoa,
              ),
              childCount: _visible.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  void _setTab(int i) => setState(() => _selected = i);
}

// ─────────────────────────────────────────────────────────────────────────────
// _Tab
// ─────────────────────────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final int index;
  final int selected;
  final ValueChanged<int> onTap;
  final ColorScheme cs;

  const _Tab({
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? cs.primary : cs.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: active ? Colors.white : cs.primary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionWidget  – renders one category (e.g. "Chocolate Based") as 2‑col grid
// ─────────────────────────────────────────────────────────────────────────────

class _SectionWidget extends StatelessWidget {
  final _Section section;
  final ColorScheme cs;
  final Color cocoa;

  const _SectionWidget({
    required this.section,
    required this.cs,
    required this.cocoa,
  });

  @override
  Widget build(BuildContext context) {
    final cakes = section.cakes;

    // Pair cakes into 2-column rows
    final rows = <Widget>[];
    for (int i = 0; i < cakes.length; i += 2) {
      final right = i + 1 < cakes.length ? cakes[i + 1] : null;
      rows
        ..add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _CakeCard(cake: cakes[i], cs: cs, cocoa: cocoa)),
                const SizedBox(width: 32),
                Expanded(
                  child: right != null
                      ? _CakeCard(cake: right, cs: cs, cocoa: cocoa)
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        )
        ..add(const SizedBox(height: 40));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 48, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header with flanking rules ──────────────────────────
          Row(
            children: [
              Expanded(child: Container(height: 0.5, color: cs.primary.withOpacity(0.25))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  section.category.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3.5,
                    color: cs.primary.withOpacity(0.55),
                  ),
                ),
              ),
              Expanded(child: Container(height: 0.5, color: cs.primary.withOpacity(0.25))),
            ],
          ),
          const SizedBox(height: 36),
          ...rows,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CakeCard  – one cake entry (name, flavours, description, price tiers)
// ─────────────────────────────────────────────────────────────────────────────

class _CakeCard extends StatelessWidget {
  final _Cake cake;
  final ColorScheme cs;
  final Color cocoa;

  const _CakeCard({required this.cake, required this.cs, required this.cocoa});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name — bold pink caps
        Text(
          cake.name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            height: 1.35,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 10),

        // Flavours — italic medium brown
        Text(
          cake.flavours,
          style: GoogleFonts.notoSerif(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: cocoa.withOpacity(0.65),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),

        // Description — italic lighter
        Text(
          cake.description,
          style: GoogleFonts.notoSerif(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: cocoa.withOpacity(0.5),
            height: 1.55,
          ),
        ),
        const SizedBox(height: 14),

        // Price tiers
        ...cake.tiers.map((t) => _TierRow(tier: t, cs: cs, cocoa: cocoa)),

        const SizedBox(height: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TierRow  – wavy squiggle + "weight | serves | price"
// ─────────────────────────────────────────────────────────────────────────────

class _TierRow extends StatelessWidget {
  final _Tier tier;
  final ColorScheme cs;
  final Color cocoa;

  const _TierRow({required this.tier, required this.cs, required this.cocoa});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Wavy squiggle matching the printed menu
          SizedBox(
            width: 34,
            height: 9,
            child: CustomPaint(painter: _WavyPainter(cs.primary.withOpacity(0.65))),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${tier.weight}  |  ${tier.serves}  |  ${tier.price}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: cocoa.withOpacity(0.6),
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
