import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:movie_max/data/models/booking.dart';
import 'package:movie_max/data/models/seat_layout.dart';
import 'package:movie_max/data/moviemax_api.dart';
import 'package:movie_max/view/screens/payment_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({
    super.key,
    required this.sessionId,
    required this.cinemaId,
    required this.cinemaName,
    required this.movieTitle,
    required this.showTime,
    this.imagePath,
  });

  final int sessionId;
  final String cinemaId;
  final String cinemaName;
  final String movieTitle;
  final DateTime showTime;
  final String? imagePath;

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  // Brand palette.
  static const _bg = Color(0xFF160A1A);
  static const _surface = Color(0xFF1F0E25);
  static const _accent = Color(0xFFFFD233);
  static const _available = Color(0xFF4ED7A8);
  static const _maxSeats = 8;

  final MovieMaxApi _api = MovieMaxApi();
  final Set<String> _selectedSeats = {};

  bool _loading = true;
  String? _error;
  SeatLayoutData? _layout;

  @override
  void initState() {
    super.initState();
    _loadLayout();
  }

  Future<void> _loadLayout() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final layout =
          await _api.fetchSeatLayout(widget.sessionId, widget.cinemaId);
      if (!mounted) {
        return;
      }
      setState(() {
        _layout = layout;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _toggleSeat(SeatCell seat) {
    if (!seat.isAvailable) {
      return;
    }

    if (!_selectedSeats.contains(seat.key) &&
        _selectedSeats.length >= _maxSeats) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _surface,
          content: Text(
            'You can select up to $_maxSeats seats at a time',
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      if (_selectedSeats.contains(seat.key)) {
        _selectedSeats.remove(seat.key);
      } else {
        _selectedSeats.add(seat.key);
      }
    });
  }

  double get _totalPrice {
    if (_layout == null) {
      return 0;
    }

    var total = 0.0;
    for (final area in _layout!.areas) {
      for (final row in area.rows) {
        for (final seat in row.seats) {
          if (_selectedSeats.contains(seat.key)) {
            total += area.price;
          }
        }
      }
    }
    return total;
  }

  List<String> get _selectedSeatLabels {
    if (_layout == null) {
      return const [];
    }
    final labels = <String>[];
    for (final area in _layout!.areas) {
      for (final row in area.rows) {
        for (final seat in row.seats) {
          if (_selectedSeats.contains(seat.key)) {
            labels.add('${seat.rowId}${seat.seatNumber}');
          }
        }
      }
    }
    return labels;
  }

  List<SelectedSeatInfo> get _selectedSeatDetails {
    if (_layout == null) {
      return const [];
    }
    final seats = <SelectedSeatInfo>[];
    for (final area in _layout!.areas) {
      for (final row in area.rows) {
        for (final seat in row.seats) {
          if (_selectedSeats.contains(seat.key)) {
            seats.add(
              SelectedSeatInfo(
                label: '${seat.rowId}${seat.seatNumber}',
                category: area.description.trim(),
                price: area.price,
              ),
            );
          }
        }
      }
    }
    return seats;
  }

  void _proceedToPayment() {
    final seats = _selectedSeatDetails;
    if (seats.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          movieTitle: widget.movieTitle,
          cinemaName: widget.cinemaName,
          showTime: widget.showTime,
          screenName: _layout?.screenName,
          imagePath: widget.imagePath ?? _layout?.movieImagePath,
          seats: seats,
          ticketTotal: _totalPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.movieTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.cinemaName}  •  ${DateFormat('dd MMM, hh:mm a').format(widget.showTime)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadLayout)
              : Column(
                  children: [
                    _Legend(available: _available, accent: _accent),
                    if (_layout!.areas.isNotEmpty)
                      _PriceStrip(areas: _layout!.areas, accent: _accent),
                    Expanded(
                      child: _SeatMapView(
                        layout: _layout!,
                        selectedSeats: _selectedSeats,
                        onSeatTap: _toggleSeat,
                        availableColor: _available,
                        selectedColor: _accent,
                        surface: _surface,
                      ),
                    ),
                    _BottomBar(
                      seatLabels: _selectedSeatLabels,
                      totalPrice: _totalPrice,
                      accent: _accent,
                      surface: _surface,
                      onPay: _proceedToPayment,
                    ),
                  ],
                ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.available, required this.accent});

  final Color available;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(color: available, label: 'Available', filled: false),
          const SizedBox(width: 22),
          _LegendItem(color: accent, label: 'Selected', filled: true),
          const SizedBox(width: 22),
          _LegendItem(color: Colors.white24, label: 'Sold', filled: true),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.filled,
  });

  final Color color;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: filled ? color : Colors.transparent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
              bottomLeft: Radius.circular(3),
              bottomRight: Radius.circular(3),
            ),
            border: Border.all(color: color, width: 1.4),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _PriceStrip extends StatelessWidget {
  const _PriceStrip({required this.areas, required this.accent});

  final List<SeatArea> areas;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < areas.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  '${areas[i].description.trim().toUpperCase()} · ₹ ${areas[i].price.toInt()}',
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.95),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeatMapView extends StatefulWidget {
  const _SeatMapView({
    required this.layout,
    required this.selectedSeats,
    required this.onSeatTap,
    required this.availableColor,
    required this.selectedColor,
    required this.surface,
  });

  final SeatLayoutData layout;
  final Set<String> selectedSeats;
  final ValueChanged<SeatCell> onSeatTap;
  final Color availableColor;
  final Color selectedColor;
  final Color surface;

  static const cellSize = 30.0;
  static const cellGap = 5.0;
  static const rowLabelWidth = 26.0;
  static const hPadding = 16.0;

  @override
  State<_SeatMapView> createState() => _SeatMapViewState();
}

class _SeatMapViewState extends State<_SeatMapView> {
  final TransformationController _controller = TransformationController();
  bool _didFit = false;
  Size _viewportSize = Size.zero;

  static const _minimapSize = 112.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTransformChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  int get _maxCols => widget.layout.areas.fold<int>(
        0,
        (max, area) => area.maxRowLength > max ? area.maxRowLength : max,
      );

  int get _totalRows => widget.layout.areas.fold<int>(
        0,
        (sum, area) => sum + area.rows.length,
      );

  /// Natural width of the seat grid (row labels + seats).
  double get _gridWidth {
    const unit = _SeatMapView.cellSize + _SeatMapView.cellGap;
    return _SeatMapView.rowLabelWidth * 2 + _maxCols * unit;
  }

  double get _contentHeight {
    const rowHeight = _SeatMapView.cellSize + _SeatMapView.cellGap + 5;
    const areaHeaderHeight = 48;
    const screenBlockHeight = 88;
    return _totalRows * rowHeight +
        widget.layout.areas.length * areaHeaderHeight +
        screenBlockHeight +
        48;
  }

  double _contentWidthFor(double viewportWidth) {
    return (_gridWidth + _SeatMapView.hPadding * 2).clamp(viewportWidth, 4000.0);
  }

  void _fitToWidth(double viewportWidth, double contentWidth) {
    if (_didFit || contentWidth <= 0) {
      return;
    }
    final scale = (viewportWidth / contentWidth).clamp(0.35, 1.0);
    if (scale < 1.0) {
      _controller.value = Matrix4.identity()..scale(scale);
    }
    _didFit = true;
  }

  double _currentScale() {
    return _controller.value.getMaxScaleOnAxis().clamp(0.35, 3.0);
  }

  Rect _viewportRectInContent(double contentWidth) {
    if (_viewportSize.isEmpty) {
      return Rect.zero;
    }
    final scale = _currentScale();
    final tx = _controller.value.getTranslation().x;
    final ty = _controller.value.getTranslation().y;

    final left = (-tx / scale).clamp(0.0, contentWidth);
    final top = (-ty / scale).clamp(0.0, _contentHeight);
    final width = (_viewportSize.width / scale).clamp(0.0, contentWidth - left);
    final height =
        (_viewportSize.height / scale).clamp(0.0, _contentHeight - top);

    return Rect.fromLTWH(left, top, width, height);
  }

  void _jumpToContentPoint(
    Offset normalizedPoint,
    double contentWidth,
  ) {
    if (_viewportSize.isEmpty) {
      return;
    }

    final scale = _currentScale();
    final contentX = normalizedPoint.dx * contentWidth;
    final contentY = normalizedPoint.dy * _contentHeight;

    final tx = _viewportSize.width / 2 - contentX * scale;
    final ty = _viewportSize.height / 2 - contentY * scale;

    _controller.value = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);
  }

  @override
  Widget build(BuildContext context) {
    final areas = widget.layout.areas;
    if (areas.isEmpty) {
      return const Center(
        child: Text(
          'No seats available',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = _contentWidthFor(constraints.maxWidth);
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _fitToWidth(constraints.maxWidth, contentWidth);
          }
        });

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _controller,
                constrained: false,
                minScale: 0.35,
                maxScale: 3.0,
                boundaryMargin: const EdgeInsets.all(80),
                child: SizedBox(
                  width: contentWidth,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _SeatMapView.hPadding,
                      12,
                      _SeatMapView.hPadding,
                      24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final area in areas)
                          _AreaSection(
                            area: area,
                            gridWidth: _maxCols,
                            selectedSeats: widget.selectedSeats,
                            onSeatTap: widget.onSeatTap,
                            availableColor: widget.availableColor,
                            selectedColor: widget.selectedColor,
                          ),
                        const SizedBox(height: 20),
                        _ScreenCurve(width: _gridWidth),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: _LayoutMinimap(
                size: _minimapSize,
                layout: widget.layout,
                maxCols: _maxCols,
                contentWidth: contentWidth,
                contentHeight: _contentHeight,
                viewportRect: _viewportRectInContent(contentWidth),
                selectedSeats: widget.selectedSeats,
                availableColor: widget.availableColor,
                selectedColor: widget.selectedColor,
                surface: widget.surface,
                onNavigate: (point) => _jumpToContentPoint(point, contentWidth),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScreenCurve extends StatelessWidget {
  const _ScreenCurve({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final w = width.clamp(180.0, 520.0);
    return Column(
      children: [
        Text(
          'Screen this way!',
          style: TextStyle(
            color: const Color(0xFFFFD233).withValues(alpha: 0.85),
            fontSize: 12,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        CustomPaint(
          size: Size(w, 36),
          painter: _ScreenPainter(),
        ),
      ],
    );
  }
}

class _ScreenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(
        size.width / 2,
        size.height * 1.35,
        size.width,
        0,
      );

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFFFD233).withValues(alpha: 0.0),
          const Color(0xFFFFD233).withValues(alpha: 0.4),
          const Color(0xFFFFD233).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFD233);

    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LayoutMinimap extends StatelessWidget {
  const _LayoutMinimap({
    required this.size,
    required this.layout,
    required this.maxCols,
    required this.contentWidth,
    required this.contentHeight,
    required this.viewportRect,
    required this.selectedSeats,
    required this.availableColor,
    required this.selectedColor,
    required this.surface,
    required this.onNavigate,
  });

  final double size;
  final SeatLayoutData layout;
  final int maxCols;
  final double contentWidth;
  final double contentHeight;
  final Rect viewportRect;
  final Set<String> selectedSeats;
  final Color availableColor;
  final Color selectedColor;
  final Color surface;
  final ValueChanged<Offset> onNavigate;

  void _handlePointer(Offset localPosition) {
    final normalized = Offset(
      (localPosition.dx / size).clamp(0.0, 1.0),
      (localPosition.dy / size).clamp(0.0, 1.0),
    );
    onNavigate(normalized);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.black.withValues(alpha: 0.35),
              child: const Text(
                'Overview',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTapDown: (details) => _handlePointer(details.localPosition),
                onPanUpdate: (details) => _handlePointer(details.localPosition),
                child: CustomPaint(
                  painter: _MinimapPainter(
                    layout: layout,
                    maxCols: maxCols,
                    contentWidth: contentWidth,
                    contentHeight: contentHeight,
                    viewportRect: viewportRect,
                    selectedSeats: selectedSeats,
                    availableColor: availableColor,
                    selectedColor: selectedColor,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter({
    required this.layout,
    required this.maxCols,
    required this.contentWidth,
    required this.contentHeight,
    required this.viewportRect,
    required this.selectedSeats,
    required this.availableColor,
    required this.selectedColor,
  });

  final SeatLayoutData layout;
  final int maxCols;
  final double contentWidth;
  final double contentHeight;
  final Rect viewportRect;
  final Set<String> selectedSeats;
  final Color availableColor;
  final Color selectedColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (contentWidth <= 0 || contentHeight <= 0) {
      return;
    }

    final scaleX = size.width / contentWidth;
    final scaleY = size.height / contentHeight;
    const rowHeight = _SeatMapView.cellSize + _SeatMapView.cellGap + 5;
    const areaHeaderHeight = 48.0;
    const hPad = _SeatMapView.hPadding;
    const unit = _SeatMapView.cellSize + _SeatMapView.cellGap;

    var y = 12.0;

    for (final area in layout.areas) {
      y += areaHeaderHeight;

      for (final row in area.rows) {
        var x = hPad + _SeatMapView.rowLabelWidth;
        final trailing = maxCols - row.seats.length;

        for (final seat in row.seats) {
          if (!seat.isAisle) {
            final paint = Paint()
              ..color = seat.isSold
                  ? Colors.white24
                  : selectedSeats.contains(seat.key)
                      ? selectedColor
                      : availableColor.withValues(alpha: 0.55);

            final rect = Rect.fromLTWH(
              x * scaleX,
              y * scaleY,
              _SeatMapView.cellSize * scaleX,
              _SeatMapView.cellSize * scaleY,
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
              paint,
            );
          }
          x += unit;
        }

        if (trailing > 0) {
          x += trailing * unit;
        }
        y += rowHeight;
      }
    }

    // Screen strip at bottom of minimap.
    final screenPaint = Paint()
      ..color = const Color(0xFFFFD233).withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final screenY = (contentHeight - 28) * scaleY;
    canvas.drawLine(
      Offset(size.width * 0.08, screenY),
      Offset(size.width * 0.92, screenY),
      screenPaint,
    );

    if (!viewportRect.isEmpty) {
      final vp = Rect.fromLTWH(
        viewportRect.left * scaleX,
        viewportRect.top * scaleY,
        viewportRect.width * scaleX,
        viewportRect.height * scaleY,
      );
      canvas.drawRect(
        vp,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        vp,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter oldDelegate) {
    return oldDelegate.viewportRect != viewportRect ||
        oldDelegate.selectedSeats != selectedSeats ||
        oldDelegate.layout != layout;
  }
}

class _AreaSection extends StatelessWidget {
  const _AreaSection({
    required this.area,
    required this.gridWidth,
    required this.selectedSeats,
    required this.onSeatTap,
    required this.availableColor,
    required this.selectedColor,
  });

  final SeatArea area;
  final int gridWidth;
  final Set<String> selectedSeats;
  final ValueChanged<SeatCell> onSeatTap;
  final Color availableColor;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.08),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${area.description.trim().toUpperCase()} - ₹ ${area.price.toInt()}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.08),
                  thickness: 1,
                ),
              ),
            ],
          ),
        ),
        ...area.rows.map(
          (row) => _SeatRowWidget(
            row: row,
            gridWidth: gridWidth,
            selectedSeats: selectedSeats,
            onSeatTap: onSeatTap,
            availableColor: availableColor,
            selectedColor: selectedColor,
          ),
        ),
      ],
    );
  }
}

class _SeatRowWidget extends StatelessWidget {
  const _SeatRowWidget({
    required this.row,
    required this.gridWidth,
    required this.selectedSeats,
    required this.onSeatTap,
    required this.availableColor,
    required this.selectedColor,
  });

  final SeatRow row;
  final int gridWidth;
  final Set<String> selectedSeats;
  final ValueChanged<SeatCell> onSeatTap;
  final Color availableColor;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    const unit = _SeatMapView.cellSize + _SeatMapView.cellGap;
    final trailing = gridWidth - row.seats.length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _SeatMapView.rowLabelWidth,
            child: Text(
              row.rowId,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...row.seats.map((seat) {
            if (seat.isAisle) {
              return const SizedBox(width: unit, height: _SeatMapView.cellSize);
            }

            final selected = selectedSeats.contains(seat.key);
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _SeatMapView.cellGap / 2,
              ),
              child: _SeatWidget(
                seat: seat,
                selected: selected,
                availableColor: availableColor,
                selectedColor: selectedColor,
                onTap: () => onSeatTap(seat),
              ),
            );
          }),
          if (trailing > 0)
            SizedBox(width: trailing * unit, height: _SeatMapView.cellSize),
          const SizedBox(width: _SeatMapView.rowLabelWidth),
        ],
      ),
    );
  }
}

class _SeatWidget extends StatelessWidget {
  const _SeatWidget({
    required this.seat,
    required this.selected,
    required this.availableColor,
    required this.selectedColor,
    required this.onTap,
  });

  final SeatCell seat;
  final bool selected;
  final Color availableColor;
  final Color selectedColor;
  final VoidCallback onTap;

  static const _radius = BorderRadius.only(
    topLeft: Radius.circular(8),
    topRight: Radius.circular(8),
    bottomLeft: Radius.circular(4),
    bottomRight: Radius.circular(4),
  );

  @override
  Widget build(BuildContext context) {
    const size = _SeatMapView.cellSize;

    if (seat.isSold) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: _radius,
          border: Border.all(color: Colors.white12),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.close,
          size: size * 0.42,
          color: Colors.white.withValues(alpha: 0.22),
        ),
      );
    }

    final Color borderColor;
    final Color fillColor;
    final Color textColor;

    if (selected) {
      borderColor = selectedColor;
      fillColor = selectedColor;
      textColor = Colors.black;
    } else {
      borderColor = availableColor;
      fillColor = availableColor.withValues(alpha: 0.10);
      textColor = availableColor;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: _radius,
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          seat.seatNumber,
          style: TextStyle(
            color: textColor,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.seatLabels,
    required this.totalPrice,
    required this.accent,
    required this.surface,
    required this.onPay,
  });

  final List<String> seatLabels;
  final double totalPrice;
  final Color accent;
  final Color surface;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final count = seatLabels.length;
    final hasSelection = count > 0;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: const Border(top: BorderSide(color: Colors.white10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasSelection) ...[
                Row(
                  children: [
                    Icon(Icons.event_seat, size: 15, color: accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        seatLabels.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasSelection
                              ? '$count Seat${count > 1 ? 's' : ''} selected'
                              : 'No seats selected',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹ ${totalPrice.toInt()}',
                          style: TextStyle(
                            color: hasSelection ? accent : Colors.white38,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: !hasSelection ? null : onPay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white12,
                      disabledForegroundColor: Colors.white38,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      hasSelection ? 'Pay  ₹${totalPrice.toInt()}' : 'Select Seats',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD233),
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}