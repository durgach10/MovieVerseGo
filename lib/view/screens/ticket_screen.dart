import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:movie_max/data/models/booking.dart';
import 'package:movie_max/services/whatsapp_share.dart';
import 'package:movie_max/view/widgets/network_poster.dart';

class TicketScreen extends StatelessWidget {
  const TicketScreen({super.key, required this.booking});

  final Booking booking;

  static const _bg = Color(0xFF160A1A);
  static const _surface = Color(0xFF1F0E25);
  static const _accent = Color(0xFFFFD233);

  String get _seatList => booking.seats.map((s) => s.label).join(', ');

  String get _showDateTime =>
      DateFormat('EEE, dd MMM yyyy · hh:mm a').format(booking.showTime);

  String _shareMessage() {
    final seatDetails = booking.seats
        .map((s) => '${s.label} (${s.category} · ₹ ${s.price.toInt()})')
        .join(', ');
    final screenLine = booking.screenName != null &&
            booking.screenName!.isNotEmpty
        ? '\nScreen: ${booking.screenName}'
        : '';

    return '''
🎬 *Super Cinemas Ticket*

*Movie:* ${booking.movieTitle}
*Cinema:* ${booking.cinemaName}$screenLine
*Show:* $_showDateTime
*Seats:* $seatDetails
*Amount paid:* ₹ ${booking.grandTotal.toInt()}
*Booking ID:* ${booking.bookingId}
*Paid via:* ${booking.paymentMethod}

Show this ticket at the cinema entrance. Enjoy the movie! 🍿''';
  }

  Future<void> _shareViaWhatsApp(BuildContext context) async {
    final opened = await WhatsAppShare.share(_shareMessage());

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'WhatsApp is not installed. Please install WhatsApp to share.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'Your Ticket',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => _goHome(context),
            child: const Text(
              'Done',
              style: TextStyle(
                color: _accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade300, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Payment successful!',
                    style: TextStyle(
                      color: Colors.green.shade200,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _BookingSummary(
              booking: booking,
              seatList: _seatList,
              showDateTime: _showDateTime,
            ),
            const SizedBox(height: 16),
            _TicketCard(
              booking: booking,
              seatList: _seatList,
              showDateTime: _showDateTime,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareViaWhatsApp(context),
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: Colors.green.shade400,
                    ),
                    label: Text(
                      'WhatsApp',
                      style: TextStyle(color: Colors.green.shade400),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade400,
                      side: BorderSide(color: Colors.green.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _goHome(context),
                    icon: const Icon(Icons.home_outlined, size: 18),
                    label: const Text('Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _BookingSummary extends StatelessWidget {
  const _BookingSummary({
    required this.booking,
    required this.seatList,
    required this.showDateTime,
  });

  final Booking booking;
  final String seatList;
  final String showDateTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TicketScreen._accent.withValues(alpha: 0.18),
            TicketScreen._surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TicketScreen._accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking.movieTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 16),
          _SummaryRow(
            icon: Icons.location_on_outlined,
            label: 'Cinema',
            value: booking.cinemaName,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.schedule,
            label: 'Show time',
            value: showDateTime,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.event_seat,
            label: 'Seat${booking.seatCount > 1 ? 's' : ''}',
            value: seatList,
            valueColor: TicketScreen._accent,
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount paid',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Including booking fee',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '₹ ${booking.grandTotal.toInt()}',
                style: const TextStyle(
                  color: TicketScreen._accent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.white38),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.booking,
    required this.seatList,
    required this.showDateTime,
  });

  final Booking booking;
  final String seatList;
  final String showDateTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TicketScreen._surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: NetworkPoster(
                    imagePath: booking.imagePath,
                    width: 72,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.movieTitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _TicketMeta(
                        icon: Icons.location_on_outlined,
                        text: booking.cinemaName,
                      ),
                      const SizedBox(height: 4),
                      _TicketMeta(
                        icon: Icons.schedule,
                        text: showDateTime,
                      ),
                      if (booking.screenName != null &&
                          booking.screenName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _TicketMeta(
                          icon: Icons.tv_outlined,
                          text: booking.screenName!,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Text(
                    'SEATS',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    seatList,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: TicketScreen._accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: booking.seats.map((seat) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: TicketScreen._accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: TicketScreen._accent.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          '${seat.label} · ₹ ${seat.price.toInt()}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _DottedDivider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FakeQrCode(seed: booking.bookingId),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking ID',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.bookingId,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _TicketDetailRow(
                        label: 'Tickets',
                        value: '₹ ${booking.ticketTotal.toInt()}',
                      ),
                      const SizedBox(height: 6),
                      _TicketDetailRow(
                        label: 'Booking fee',
                        value: '₹ ${booking.bookingFee.toInt()}',
                      ),
                      const SizedBox(height: 6),
                      _TicketDetailRow(
                        label: 'Total paid',
                        value: '₹ ${booking.grandTotal.toInt()}',
                        highlight: true,
                      ),
                      const SizedBox(height: 6),
                      _TicketDetailRow(
                        label: 'Paid via',
                        value: booking.paymentMethod,
                      ),
                      const SizedBox(height: 6),
                      _TicketDetailRow(
                        label: 'Booked on',
                        value: DateFormat('dd MMM yyyy, hh:mm a')
                            .format(booking.bookedAt),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: TicketScreen._accent.withValues(alpha: 0.12),
            child: Text(
              '${booking.seatCount} seat${booking.seatCount > 1 ? 's' : ''} · '
              '${booking.cinemaName} · $showDateTime',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TicketScreen._accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketMeta extends StatelessWidget {
  const _TicketMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white38),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _TicketDetailRow extends StatelessWidget {
  const _TicketDetailRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight ? TicketScreen._accent : Colors.white,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            fontSize: highlight ? 14 : 12,
          ),
        ),
      ],
    );
  }
}

class _DottedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 6.0;
          const dashSpace = 4.0;
          final dashCount =
              (constraints.maxWidth / (dashWidth + dashSpace)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return Container(
                width: dashWidth,
                height: 1,
                color: Colors.white24,
              );
            }),
          );
        },
      ),
    );
  }
}

class _FakeQrCode extends StatelessWidget {
  const _FakeQrCode({required this.seed});

  final String seed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: CustomPaint(
        painter: _FakeQrPainter(seed: seed),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _FakeQrPainter extends CustomPainter {
  _FakeQrPainter({required this.seed});

  final String seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed.hashCode);
    const cells = 12;
    final cell = size.width / cells;
    final paint = Paint()..color = Colors.black;

    for (var row = 0; row < cells; row++) {
      for (var col = 0; col < cells; col++) {
        final isCorner = (row < 3 && col < 3) ||
            (row < 3 && col >= cells - 3) ||
            (row >= cells - 3 && col < 3);
        final filled = isCorner || random.nextBool();
        if (filled) {
          canvas.drawRect(
            Rect.fromLTWH(col * cell, row * cell, cell, cell),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FakeQrPainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}