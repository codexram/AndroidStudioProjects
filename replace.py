import sys

with open(r'd:\Web_Dev\CinemaNow\CinemaNow\lib\main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start_marker = 'class HomePage extends StatefulWidget {'
end_marker = '// ─── ALL MOVIES PAGE ───────────────────────────────────────────────────────'

start_idx = content.find(start_marker)
end_idx = content.find(end_marker)

if start_idx == -1 or end_idx == -1:
    print('Markers not found!')
    print(f'start_idx: {start_idx}, end_idx: {end_idx}')
    sys.exit(1)

new_code = '''class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override bool get wantKeepAlive => true;

  final _heroCtrl = PageController(viewportFraction: 0.82);
  late final AnimationController _autoScrollTimer;
  int _heroIdx = 0;

  int _catIdx = 0; 
  int _subCatIdx = 0;
  String _genre    = 'All';
  String _language = 'All';
  bool   _showFilters = false;

  static const _catLabels = ['Now Showing', 'Coming Soon'];
  static const _subCatLabels = ['All', '🎬 Bollywood', '🌟 Hollywood', '🎭 South Indian', '⭐ Top Rated'];
  static const _genres    = ['All', 'Action', 'Drama', 'Comedy', 'Animation', 'Thriller', 'Biography', 'Sci-Fi', 'Horror', 'Romance'];
  static const _langs     = ['All', 'Hindi', 'English', 'Tamil', 'Telugu', 'Malayalam', 'Kannada'];

  @override void initState() {
    super.initState();
    _autoScrollTimer = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _autoScrollTimer.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        _autoScrollTimer.reset();
        _autoScrollTimer.forward();
        final ms = context.read<MovieService>();
        final len = ms.trending.length;
        if (len > 0) {
          final next = (_heroIdx + 1) % len.clamp(1, 10);
          _heroCtrl.animateToPage(next, duration: 800.ms, curve: Curves.fastOutSlowIn);
        }
      }
    });
    _autoScrollTimer.forward();
  }

  @override void dispose() {
    _heroCtrl.dispose();
    _autoScrollTimer.dispose();
    super.dispose();
  }

  List<OmdbMovie> _moviesForTab(MovieService ms) {
    if (_catIdx == 1) return ms.upcoming;
    switch (_subCatIdx) {
      case 1: return [...ms.bollywoodNew, ...ms.bollywoodClassic];
      case 2: return [...ms.hollywoodNew, ...ms.hollywoodClassic];
      case 3: return [...ms.tollywoodNew, ...ms.tollywoodClassic];
      case 4: return ms.topRated;
      default: return ms.nowPlaying;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final d  = context.watch<ThemeService>().isDark;
    final ms = context.watch<MovieService>();

    return Scaffold(
      backgroundColor: C.bg(d),
      extendBodyBehindAppBar: true,
      body: EdgeHapticScroll(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(d, ms),
            
            SliverToBoxAdapter(child: Column(children: [
              if (ms.trending.isNotEmpty) _buildHeroCarousel(ms.trending, d),
              _buildQuickStats(d, ms),
              _buildCategoryTabs(d),
              if (_catIdx == 0) _buildSubCategoryTabs(d),
              _buildFilterToggle(d),
              if (_showFilters) ...[
                _buildGenreChips(d),
                _buildLanguageChips(d),
              ],
              const SizedBox(height: 24),
            ])),

            _buildMovieGridSliver(ms, d),

            if (_catIdx == 0 && _subCatIdx == 0) ...[
              SliverToBoxAdapter(child: Column(children: [
                const SizedBox(height: 16),
                if (ms.trending.isNotEmpty)
                  _buildHorizontalSection('🔥 Trending Now', ms.trending, d, accent: C.rose),
                if (ms.bollywoodNew.isNotEmpty)
                  _buildHorizontalSection('🎬 Bollywood Hits', ms.bollywoodNew, d, accent: C.bollywood),
                if (ms.tollywoodNew.isNotEmpty)
                  _buildHorizontalSection('🎭 South Indian', ms.tollywoodNew, d, accent: C.tollywood),
                if (ms.hollywoodNew.isNotEmpty)
                  _buildHorizontalSection('🌟 Hollywood', ms.hollywoodNew, d, accent: C.hollywood),
                if (ms.topRated.isNotEmpty)
                  _buildHorizontalSection('⭐ All-Time Greats', ms.topRated, d, accent: C.gold),
              ])),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool d, MovieService ms) => SliverAppBar(
    floating: true, pinned: true, 
    backgroundColor: C.bg(d).withOpacity(0.7),
    elevation: 0,
    flexibleSpace: ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(color: Colors.transparent),
      ),
    ),
    title: _LogoWidget(isDark: d),
    actions: [
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
        child: Stack(children: [
          Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: d ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: d ? Colors.white10 : Colors.black12)),
              child: const Icon(Icons.notifications_outlined, size: 18, color: C.txSecD)),
          Positioned(top: 6, right: 6, child: Container(
              width: 7, height: 7,
              decoration: const BoxDecoration(color: C.rose, shape: BoxShape.circle, boxShadow: [BoxShadow(color: C.rose, blurRadius: 4)]))),
        ]),
      ),
      IconButton(
          icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: d ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), 
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: d ? Colors.white10 : Colors.black12)),
              child: Icon(d ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 18, color: d ? C.txSecD : C.txSecL)),
          onPressed: () => context.read<ThemeService>().toggle()),
      const SizedBox(width: 4),
    ],
  );

  Widget _buildHeroCarousel(List<OmdbMovie> movies, bool d) {
    final ms = context.read<MovieService>();
    final limited = movies.take(10).toList();
    return RepaintBoundary(
      child: Column(children: [
        SizedBox(
          height: 460,
          child: PageView.builder(
            controller: _heroCtrl,
            itemCount: limited.length,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _heroIdx = i);
            },
            itemBuilder: (ctx, i) {
              final m   = limited[i];
              final sel = i == _heroIdx;
              final isComingSoon = ms.upcoming.any((mov) => mov.imdbId == m.imdbId);
              return AnimatedContainer(
                duration: 400.ms,
                curve: Curves.easeOutQuart,
                margin: EdgeInsets.only(
                  top: sel ? 20 : 50,
                  bottom: sel ? 20 : 40,
                  right: 12,
                  left: 12,
                ),
                child: _HeroCard(movie: m, selected: sel, isComingSoon: isComingSoon),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(
          limited.length,
          (i) => AnimatedContainer(
            duration: 300.ms,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == _heroIdx ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
                color: i == _heroIdx ? C.gold : (d ? Colors.white24 : Colors.black26),
                borderRadius: BorderRadius.circular(4),
                boxShadow: i == _heroIdx ? [BoxShadow(color: C.gold.withOpacity(0.6), blurRadius: 10)] : null,
            ),
          ),
        )),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildQuickStats(bool d, MovieService ms) {
    final total = ms.trending.length + ms.bollywoodNew.length +
        ms.hollywoodNew.length + ms.tollywoodNew.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: GlassBox(
        radius: 20, blur: 15, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        border: Border.all(color: d ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _StatChip(Icons.movie_rounded, f'{total}+ Movies', C.gold, d),
          Container(width: 1, height: 28, color: d ? Colors.white10 : Colors.black12),
          _StatChip(Icons.theaters_rounded, '5 Theaters', C.cyan, d),
          Container(width: 1, height: 28, color: d ? Colors.white10 : Colors.black12),
          _StatChip(Icons.local_offer_rounded, '6 Offers', C.green, d),
        ]).animate().fadeIn(delay: 200.ms),
      )
    );
  }

  Widget _buildCategoryTabs(bool d) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
    child: SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _catLabels.length,
        itemBuilder: (_, i) {
          final sel = i == _catIdx;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() { _catIdx = i; _subCatIdx = 0; _genre = 'All'; _language = 'All'; });
            },
            child: AnimatedContainer(
              duration: 300.ms,
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                gradient: sel ? C.gradGold : null,
                color: sel ? null : (d ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sel ? C.gold.withOpacity(0.5) : (d ? Colors.white10 : Colors.black12)),
                boxShadow: sel ? [BoxShadow(
                    color: C.gold.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))] : null,
              ),
              child: Row(
                children: [
                  if (sel) ...[
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                  ],
                  Text(_catLabels[i], style: TextStyle(
                      color: sel ? Colors.black : (d ? C.txSecD : C.txSecL),
                      fontWeight: FontWeight.w800, fontSize: 14)),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _buildSubCategoryTabs(bool d) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
    child: SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _subCatLabels.length,
        itemBuilder: (_, i) {
          final sel = i == _subCatIdx;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() { _subCatIdx = i; _genre = 'All'; _language = 'All'; });
            },
            child: AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: sel ? C.gold.withOpacity(0.15) : (d ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: sel ? C.gold : (d ? Colors.white10 : Colors.black12)),
                boxShadow: sel ? [BoxShadow(color: C.gold.withOpacity(0.1), blurRadius: 8)] : null,
              ),
              child: Text(_subCatLabels[i], style: TextStyle(
                  color: sel ? C.gold : (d ? C.txSecD : C.txSecL),
                  fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          );
        },
      ),
    ),
  );

  Widget _buildFilterToggle(bool d) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: GestureDetector(
      onTap: () => setState(() => _showFilters = !_showFilters),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _showFilters ? C.gold.withOpacity(0.12) : (d ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _showFilters ? C.gold : (d ? Colors.white10 : Colors.black12)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.tune_rounded,
              color: _showFilters ? C.gold : (d ? C.txSecD : C.txSecL), size: 16),
          const SizedBox(width: 8),
          Text("Filter & Sort",
              style: TextStyle(
                  color: _showFilters ? C.gold : (d ? C.txSecD : C.txSecL),
                  fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Icon(_showFilters ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: _showFilters ? C.gold : (d ? C.txMutD : C.txMutL), size: 18),
          if (_genre != "All" || _language != "All") ...[
            const SizedBox(width: 10),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: C.gold.withOpacity(0.5), blurRadius: 4)]),
                child: const Text("Active", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800))),
          ],
        ]),
      ),
    ),
  );

  Widget _buildGenreChips(bool d) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 16, bottom: 10),
          child: Text("Genre", style: TextStyle(
              color: d ? C.txSecD : C.txSecL, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
      SizedBox(height: 38, child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _genres.length,
        itemBuilder: (_, i) {
          final g   = _genres[i];
          final sel = g == _genre;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _genre = g); },
            child: AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  gradient: sel ? C.gradGold : null,
                  color: sel ? null : (d ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? C.gold : (d ? Colors.white10 : Colors.black12))),
              child: Text(g, style: TextStyle(
                  color: sel ? Colors.black : (d ? C.txSecD : C.txSecL),
                  fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          );
        },
      )),
    ]),
  );

  Widget _buildLanguageChips(bool d) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 16, bottom: 10),
          child: Text("Language", style: TextStyle(
              color: d ? C.txSecD : C.txSecL, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
      SizedBox(height: 38, child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _langs.length,
        itemBuilder: (_, i) {
          final l   = _langs[i];
          final sel = l == _language;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _language = l); },
            child: AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: sel ? C.indigo.withOpacity(0.2) : (d ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? C.indigo : (d ? Colors.white10 : Colors.black12))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.language_rounded, size: 14,
                    color: sel ? C.indigo : (d ? C.txMutD : C.txMutL)),
                const SizedBox(width: 6),
                Text(l, style: TextStyle(
                    color: sel ? C.indigo : (d ? C.txMutD : C.txMutL),
                    fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
          );
        },
      )),
      const SizedBox(height: 8),
    ]),
  );

  Widget _buildMovieGridSliver(MovieService ms, bool d) {
    var movies = _moviesForTab(ms);
    if (_genre    != "All") movies = movies.where((m) => m.genres.contains(_genre)).toList();
    if (_language != "All") movies = movies.where((m) => m.languages.contains(_language)).toList();

    if (ms.loadingHero && movies.isEmpty) return _buildShimmerGridSliver();

    if (movies.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(children: [
            Icon(Icons.search_off_rounded, color: d ? C.txMutD : C.txMutL, size: 56),
            const SizedBox(height: 16),
            Text("No movies match your filters", style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 16)),
            const SizedBox(height: 16),
            TextButton(
                onPressed: () => setState(() { _genre = "All"; _language = "All"; }),
                child: const Text("Clear filters", style: TextStyle(color: C.gold, fontWeight: FontWeight.w800, fontSize: 15))),
          ]),
        ),
      );
    }

    final currentTitle = _catIdx == 0 
        ? (_subCatIdx == 0 ? "Now Showing" : _subCatLabels[_subCatIdx])
        : "Coming Soon";

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Row(children: [
              Container(width: 5, height: 20,
                  decoration: BoxDecoration(gradient: C.gradGold, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 12),
              Text(currentTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: d ? C.txPrimD : C.txPrimL)),
              const Spacer(),
              Text(f"{movies.length} movies", style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 13)),
            ]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 0.60,
                crossAxisSpacing: 16, mainAxisSpacing: 20),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _GridCard(movie: movies[i])
                  .animate().fadeIn(delay: (i * 30).ms)
                  .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic),
              childCount: movies.length > 10 ? 10 : movies.length,
            ),
          ),
          if (movies.length > 10)
            SliverToBoxAdapter(
              child: Padding(padding: const EdgeInsets.only(top: 20),
                  child: GoldBtn(
                    label: f"See all {movies.length} movies",
                    height: 52,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AllMoviesPage(title: currentTitle, movies: movies))),
                  )),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerGridSliver() => SliverPadding(
    padding: const EdgeInsets.all(16),
    sliver: SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 0.60,
          crossAxisSpacing: 16, mainAxisSpacing: 20),
      delegate: SliverChildBuilderDelegate((_, __) => const ShimmerBox(width: double.infinity, height: double.infinity, radius: 20), childCount: 6),
    ),
  );

  Widget _buildHorizontalSection(
      String title, List<OmdbMovie> movies, bool d, {Color accent = C.gold}
      ) {
    if (movies.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 28, 20, 16), child: Row(children: [
        Container(width: 5, height: 20,
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3), boxShadow: [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 6)])),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w900, color: d ? C.txPrimD : C.txPrimL))),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => AllMoviesPage(title: title, movies: movies)));
          },
          child: Row(children: [
            Text("See all", style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w700)),
            Icon(Icons.chevron_right_rounded, color: accent, size: 18),
          ]),
        ),
      ])),
      RepaintBoundary(child: SizedBox(height: 270, child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: movies.length,
        cacheExtent: 500.0,
        itemBuilder: (ctx, i) => Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 20), // bottom padding for glow
            child: _PosterCard(movie: movies[i], accent: accent)).animate().fadeIn(delay: (i * 30).ms),
      ))),
    ]);
  }
}

// ─── STAT CHIP ─────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  const _StatChip(this.icon, this.label, this.color, this.isDark);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)],
      ),
      child: Icon(icon, color: color, size: 16),
    ),
    const SizedBox(width: 10),
    Text(label, style: TextStyle(color: isDark ? C.txPrimD : C.txPrimL, fontSize: 13, fontWeight: FontWeight.w800)),
  ]);
}

// ─── HERO CARD ─────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final OmdbMovie movie;
  final bool selected;
  final bool isComingSoon;
  const _HeroCard({required this.movie, this.selected = true, this.isComingSoon = false});

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    return PressableScale(
      onTap: () => _toDetail(context, movie),
      scale: 0.96,
      child: Hero(
        tag: 'poster-${movie.imdbId}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: selected ? [
              BoxShadow(color: C.gold.withOpacity(0.35), blurRadius: 30, offset: const Offset(0, 15))
            ] : [
              BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 10))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(fit: StackFit.expand, children: [
              CachedNetworkImage(
                imageUrl: movie.posterUrl, fit: BoxFit.cover,
                alignment: Alignment(0, selected ? -0.2 : 0.0), // Subtle parallax
                fadeInDuration: 400.ms, fadeOutDuration: 200.ms,
                memCacheHeight: 800,
                placeholder: (_, __) => const ShimmerBox(width: double.infinity, height: double.infinity, radius: 0),
                errorWidget: (_, __, ___) => Container(
                    color: C.card(d),
                    child: const Center(child: Icon(Icons.movie_rounded, color: C.gold, size: 52))),
              ),
              Container(decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.95)],
                  stops: const [0.3, 1.0]))),
              Positioned(top: 16, right: 16,
                  child: Row(children: [
                    if (movie.hasTrailer)
                      const GlassBox(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          radius: 20, blur: 15, tint: Colors.black,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.play_circle_filled_rounded, color: C.rose, size: 16),
                            SizedBox(width: 6),
                            Text("TRAILER", style: TextStyle(
                                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          ])),
                  ])),
              Positioned(top: 16, left: 16,
                  child: GlassBox(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      radius: 20, blur: 15, tint: Colors.black,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(isComingSoon ? Icons.event_available_rounded : Icons.local_fire_department_rounded, color: C.gold, size: 14),
                        const SizedBox(width: 6),
                        Text(isComingSoon ? "COMING SOON" : "TRENDING", style: const TextStyle(
                            color: C.gold, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ]))),
              Positioned(bottom: 24, left: 24, right: 24, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(spacing: 8, children: movie.genres.take(3).map((g) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white30)),
                      child: Text(g, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)))).toList()),
                  const SizedBox(height: 12),
                  Text(movie.title, style: const TextStyle(
                      color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900,
                      height: 1.1, shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4))]),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(children: [
                    RatingBadge(movie.rating),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Text(movie.year, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
                    if (movie.languages.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.language_rounded, color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(movie.languages.first, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ]),
                  if (selected) ...[
                    const SizedBox(height: 18),
                    PressableScale(
                      onTap: isComingSoon ? null : () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => TheaterSelectPage(movie: movie))),
                      child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              gradient: isComingSoon ? null : C.gradGold,
                              color: isComingSoon ? Colors.white.withOpacity(0.2) : null,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isComingSoon ? null : [BoxShadow(color: C.gold.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 6))]),
                          child: Text(isComingSoon ? "Notify Me" : "Book Tickets", style: TextStyle(
                              color: isComingSoon ? Colors.white70 : Colors.black,
                              fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5))),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
                  ]
                ],
              )),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── POSTER CARD ───────────────────────────────────────────────────────────
class _PosterCard extends StatelessWidget {
  final OmdbMovie movie;
  final Color accent;
  const _PosterCard({required this.movie, this.accent = C.gold});
  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    return PressableScale(
      onTap: () => _toDetail(context, movie),
      scale: 0.95,
      child: SizedBox(width: 140, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Hero(
              tag: 'poster-${movie.imdbId}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: movie.posterUrl, width: 140, height: 200, fit: BoxFit.cover,
                  fadeInDuration: 300.ms, memCacheHeight: 400,
                  placeholder: (_, __) => const ShimmerBox(width: 140, height: 200, radius: 20),
                  errorWidget: (_, __, ___) => Container(
                      width: 140, height: 200,
                      decoration: BoxDecoration(color: C.card(d), borderRadius: BorderRadius.circular(20)),
                      child: const Center(child: Icon(Icons.movie_rounded, color: C.gold, size: 40))),
                ),
              ),
            ),
          ),
          Positioned(top: 10, right: 10, child: RatingBadge(movie.rating, small: true)),
          Positioned(top: 10, left: 10, child: _WishBtn(movie: movie, small: true)),
          if (movie.hasTrailer)
            Positioned(bottom: -10, right: 10, child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(gradient: C.gradRose, shape: BoxShape.circle, boxShadow: [BoxShadow(color: C.rose.withOpacity(0.5), blurRadius: 8)]),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20))),
        ]),
        const SizedBox(height: 16),
        Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 4),
        Text(movie.genres.isNotEmpty ? movie.genres.first : "",
            style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 12, fontWeight: FontWeight.w600)),
      ])),
    );
  }
}

// ─── GRID CARD ─────────────────────────────────────────────────────────────
class _GridCard extends StatelessWidget {
  final OmdbMovie movie;
  const _GridCard({required this.movie});
  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeService>().isDark;
    return PressableScale(
      onTap: () => _toDetail(context, movie),
      scale: 0.96,
      child: Container(
        decoration: BoxDecoration(
          color: C.card(d), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: C.border(d)),
          boxShadow: d ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))] : [BoxShadow(
              color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(fit: StackFit.expand, children: [
              Hero(
                tag: 'poster-${movie.imdbId}',
                child: CachedNetworkImage(
                  imageUrl: movie.posterUrl, fit: BoxFit.cover,
                  fadeInDuration: 300.ms, memCacheHeight: 400,
                  placeholder: (_, __) => const ShimmerBox(width: double.infinity, height: double.infinity, radius: 0),
                  errorWidget: (_, __, ___) => Container(
                      color: C.card(d),
                      child: const Center(child: Icon(Icons.movie_rounded, color: C.gold, size: 40))),
                ),
              ),
              Positioned.fill(child: Container(decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                      stops: const [0, 0.6])))),
              Positioned(bottom: 10, left: 10, right: 10,
                  child: Row(children: [
                    RatingBadge(movie.rating, small: true),
                    const Spacer(),
                    _WishBtn(movie: movie, small: true),
                  ])),
              if (movie.hasTrailer)
                Positioned(top: 10, right: 10, child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(color: C.rose.withOpacity(0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: C.rose.withOpacity(0.5), blurRadius: 6)]),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14))),
            ]),
          )),
          Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 12), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: d ? C.txPrimD : C.txPrimL, fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 4),
            Text(movie.genres.take(2).join(" · "),
                style: TextStyle(color: d ? C.txSecD : C.txSecL, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
          )),
        ]),
      ),
    );
  }
}
\n'''

new_content = content[:start_idx] + new_code + content[end_idx:]

with open(r'd:\Web_Dev\CinemaNow\CinemaNow\lib\main.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)

print('Replacement successful')
