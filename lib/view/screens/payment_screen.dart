import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:movieversego/data/models/booking.dart';
import 'package:movieversego/view/screens/ticket_screen.dart';
import 'package:movieversego/view/widgets/network_poster.dart';


class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.movieTitle,
    required this.cinemaName,
    required this.showTime,
    required this.seats,
    required this.ticketTotal,
    this.screenName,
    this.imagePath,
  });

  final String movieTitle;
  final String cinemaName;
  final String? screenName;
  final DateTime showTime;
  final String? imagePath;
  final List<SelectedSeatInfo> seats;
  final double ticketTotal;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const _bg = Color(0xFF160A1A);
  static const _surface = Color(0xFF1F0E25);
  static const _accent = Color(0xFFFFD233);

  static const _methods = [
    _PaymentMethod(
      id: 'upi',
      label: 'UPI',
      subtitle: 'Google Pay, PhonePe, Paytm',
      icon: Icons.account_balance_wallet_outlined,
    ),
    _PaymentMethod(
      id: 'card',
      label: 'Credit / Debit Card',
      subtitle: 'Visa, Mastercard, RuPay',
      icon: Icons.credit_card_outlined,
    ),
    _PaymentMethod(
      id: 'netbanking',
      label: 'Net Banking',
      subtitle: 'All major banks',
      icon: Icons.account_balance_outlined,
    ),
    _PaymentMethod(
      id: 'wallet',
      label: 'Super Wallet',
      subtitle: 'Instant checkout',
      icon: Icons.wallet_outlined,
    ),
  ];

  String _selectedMethod = _methods.first.id;
  bool _processing = false;

  double get _bookingFee => Booking.bookingFeeFor(widget.seats.length);
  double get _grandTotal => widget.ticketTotal + _bookingFee;

  Future<void> _pay() async {
    if (_processing) {
      return;
    }

    setState(() => _processing = true);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _ProcessingDialog(),
    );

    if (!mounted) {
      return;
    }

    final method = _methods.firstWhere((m) => m.id == _selectedMethod);
    final booking = Booking.fromSelection(
      movieTitle: widget.movieTitle,
      cinemaName: widget.cinemaName,
      showTime: widget.showTime,
      seats: widget.seats,
      paymentMethod: method.label,
      screenName: widget.screenName,
      imagePath: widget.imagePath,
    );

    if (!mounted) {
      return;
    }

    setState(() => _processing = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TicketScreen(booking: booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text(
          'Payment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OrderSummary(
                    movieTitle: widget.movieTitle,
                    cinemaName: widget.cinemaName,
                    screenName: widget.screenName,
                    showTime: widget.showTime,
                    imagePath: widget.imagePath,
                    seats: widget.seats,
                    ticketTotal: widget.ticketTotal,
                    bookingFee: _bookingFee,
                    grandTotal: _grandTotal,
                    accent: _accent,
                    surface: _surface,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Choose payment method',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._methods.map(
                    (method) => _MethodTile(
                      method: method,
                      selected: _selectedMethod == method.id,
                      accent: _accent,
                      surface: _surface,
                      onTap: _processing
                          ? null
                          : () => setState(() => _selectedMethod = method.id),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 18,
                          color: Colors.green.shade300,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Demo mode — no real payment is processed.',
                            style: TextStyle(
                              color: Colors.green.shade200,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _PayBar(
            total: _grandTotal,
            processing: _processing,
            accent: _accent,
            surface: _surface,
            onPay: _pay,
          ),
        ],
      ),
    );
  }
}

class _PaymentMethod {
  const _PaymentMethod({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({
    required this.movieTitle,
    required this.cinemaName,
    required this.showTime,
    required this.seats,
    required this.ticketTotal,
    required this.bookingFee,
    required this.grandTotal,
    required this.accent,
    required this.surface,
    this.screenName,
    this.imagePath,
  });

  final String movieTitle;
  final String cinemaName;
  final String? screenName;
  final DateTime showTime;
  final String? imagePath;
  final List<SelectedSeatInfo> seats;
  final double ticketTotal;
  final double bookingFee;
  final double grandTotal;
  final Color accent;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: NetworkPoster(
                  imagePath: imagePath,
                  width: 56,
                  height: 76,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movieTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cinemaName,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        DateFormat('EEE, dd MMM · hh:mm a').format(showTime),
                        if (screenName != null && screenName!.isNotEmpty)
                          screenName,
                      ].join('  •  '),
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          Text(
            seats.map((s) => s.label).join(', '),
            style: TextStyle(
              color: accent.withValues(alpha: 0.95),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${seats.length} ticket${seats.length > 1 ? 's' : ''}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 14),
          _PriceRow(label: 'Ticket(s)', value: ticketTotal),
          const SizedBox(height: 6),
          _PriceRow(label: 'Booking fee', value: bookingFee),
          const SizedBox(height: 10),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 10),
          _PriceRow(
            label: 'Total',
            value: grandTotal,
            bold: true,
            accent: accent,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.accent,
  });

  final String label;
  final double value;
  final bool bold;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: bold ? Colors.white : Colors.white60,
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          '₹ ${value.toInt()}',
          style: TextStyle(
            color: accent ?? (bold ? Colors.white : Colors.white70),
            fontSize: bold ? 16 : 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.accent,
    required this.surface,
    required this.onTap,
  });

  final _PaymentMethod method;
  final bool selected;
  final Color accent;
  final Color surface;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? accent : Colors.white12,
                width: selected ? 1.8 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected
                        ? accent.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    method.icon,
                    color: selected ? accent : Colors.white70,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        method.subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? accent : Colors.white38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PayBar extends StatelessWidget {
  const _PayBar({
    required this.total,
    required this.processing,
    required this.accent,
    required this.surface,
    required this.onPay,
  });

  final double total;
  final bool processing;
  final Color accent;
  final Color surface;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: surface,
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Amount payable',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  Text(
                    '₹ ${total.toInt()}',
                    style: TextStyle(
                      color: accent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: processing ? null : onPay,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: processing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      'Pay ₹ ${total.toInt()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessingDialog extends StatefulWidget {
  const _ProcessingDialog();

  static const _duration = Duration(seconds: 5);

  @override
  State<_ProcessingDialog> createState() => _ProcessingDialogState();
}

class _ProcessingDialogState extends State<_ProcessingDialog>
    with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFFFFD233);

  static const _messages = [
    'Your ticket is being read...',
    'Sizzling your seats...',
    'Popping fresh popcorn...',
    'Almost ready...',
  ];

  late final AnimationController _progressController;
  Timer? _letterTimer;
  int _messageIndex = 0;
  int _visibleChars = 0;
  bool _transitioning = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _ProcessingDialog._duration,
    )..forward();

    _letterTimer = Timer.periodic(const Duration(milliseconds: 55), _tickLetter);

    Future<void>.delayed(_ProcessingDialog._duration, () {
      _letterTimer?.cancel();
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _tickLetter(Timer timer) {
    if (!mounted || _transitioning) {
      return;
    }

    final message = _messages[_messageIndex];
    if (_visibleChars < message.length) {
      setState(() => _visibleChars++);
      return;
    }

    _transitioning = true;
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _messageIndex = (_messageIndex + 1) % _messages.length;
        _visibleChars = 0;
        _transitioning = false;
      });
    });
  }

  @override
  void dispose() {
    _letterTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1F0E25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(
                color: _accent,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: Center(
                child: _SizzlingTypewriter(
                  text: _messages[_messageIndex].substring(
                    0,
                    _visibleChars.clamp(0, _messages[_messageIndex].length),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, _) {
                final secondsLeft =
                    (5 * (1 - _progressController.value)).ceil().clamp(0, 5);
                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progressController.value,
                        minHeight: 4,
                        backgroundColor: Colors.white12,
                        color: _accent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      secondsLeft > 0
                          ? 'Redirecting in $secondsLeft sec'
                          : 'Opening your ticket...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SizzlingTypewriter extends StatelessWidget {
  const _SizzlingTypewriter({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return Text(
        '|',
        style: TextStyle(
          color: _ProcessingDialogState._accent.withValues(alpha: 0.6),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final prefix = text.length > 1 ? text.substring(0, text.length - 1) : '';
    final lastChar = text[text.length - 1];

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (prefix.isNotEmpty)
          Text(
            prefix,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        _SizzleLetter(
          key: ValueKey(text.length),
          char: lastChar,
        ),
      ],
    );
  }
}

class _SizzleLetter extends StatefulWidget {
  const _SizzleLetter({super.key, required this.char});

  final String char;

  @override
  State<_SizzleLetter> createState() => _SizzleLetterState();
}

class _SizzleLetterState extends State<_SizzleLetter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.35), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 55),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _glow = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
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
        return Transform.scale(
          scale: _scale.value,
          child: Text(
            widget.char,
            style: TextStyle(
              color: Color.lerp(
                _ProcessingDialogState._accent,
                Colors.white,
                _glow.value * 0.35,
              ),
              fontSize: 15,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: _ProcessingDialogState._accent
                      .withValues(alpha: 0.6 * (1 - _glow.value)),
                  blurRadius: 8 * (1 - _glow.value),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}