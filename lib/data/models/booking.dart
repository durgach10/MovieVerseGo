class SelectedSeatInfo {
  const SelectedSeatInfo({
    required this.label,
    required this.category,
    required this.price,
  });

  final String label;
  final String category;
  final double price;
}

class Booking {
  const Booking({
    required this.bookingId,
    required this.movieTitle,
    required this.cinemaName,
    required this.showTime,
    required this.seats,
    required this.ticketTotal,
    required this.bookingFee,
    required this.grandTotal,
    required this.bookedAt,
    required this.paymentMethod,
    this.screenName,
    this.imagePath,
  });

  final String bookingId;
  final String movieTitle;
  final String cinemaName;
  final String? screenName;
  final DateTime showTime;
  final String? imagePath;
  final List<SelectedSeatInfo> seats;
  final double ticketTotal;
  final double bookingFee;
  final double grandTotal;
  final DateTime bookedAt;
  final String paymentMethod;

  int get seatCount => seats.length;

  static String generateBookingId() {
    final now = DateTime.now();
    final stamp = now.millisecondsSinceEpoch.toString();
    return 'SC${stamp.substring(stamp.length - 10)}';
  }

  static double bookingFeeFor(int seatCount) {
    return seatCount * 28.0;
  }

  factory Booking.fromSelection({
    required String movieTitle,
    required String cinemaName,
    required DateTime showTime,
    required List<SelectedSeatInfo> seats,
    required String paymentMethod,
    String? screenName,
    String? imagePath,
  }) {
    final ticketTotal =
        seats.fold<double>(0, (sum, seat) => sum + seat.price);
    final bookingFee = bookingFeeFor(seats.length);
    return Booking(
      bookingId: generateBookingId(),
      movieTitle: movieTitle,
      cinemaName: cinemaName,
      screenName: screenName,
      showTime: showTime,
      imagePath: imagePath,
      seats: seats,
      ticketTotal: ticketTotal,
      bookingFee: bookingFee,
      grandTotal: ticketTotal + bookingFee,
      bookedAt: DateTime.now(),
      paymentMethod: paymentMethod,
    );
  }
}