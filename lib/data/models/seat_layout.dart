class SeatCell {
  const SeatCell({
    required this.gridNum,
    required this.seatNumber,
    required this.status,
    required this.rowId,
  });

  final String gridNum;
  final String seatNumber;
  final String status;
  final String rowId;

  bool get isAisle => status == '10';
  bool get isSold => status == '1';
  bool get isAvailable => status == '0';

  String get key => '$rowId-$seatNumber';
}

class SeatRow {
  const SeatRow({
    required this.rowId,
    required this.seats,
  });

  final String rowId;
  final List<SeatCell> seats;
}

extension SeatLayoutMetrics on SeatArea {
  /// Widest row in this area — rows are padded to this width so columns align.
  int get maxRowLength {
    var max = 0;
    for (final row in rows) {
      if (row.seats.length > max) {
        max = row.seats.length;
      }
    }
    return max;
  }
}

class SeatArea {
  const SeatArea({
    required this.description,
    required this.price,
    required this.rows,
  });

  final String description;
  final double price;
  final List<SeatRow> rows;
}

class SeatLayoutData {
  const SeatLayoutData({
    required this.areas,
    required this.cinemaName,
    required this.screenName,
    required this.showTime,
    required this.movieTitle,
    required this.movieImagePath,
    required this.sessionId,
    required this.cinemaId,
  });

  final List<SeatArea> areas;
  final String cinemaName;
  final String screenName;
  final DateTime showTime;
  final String movieTitle;
  final String movieImagePath;
  final int sessionId;
  final String cinemaId;

  factory SeatLayoutData.fromJson(Map<String, dynamic> json) {
    final session = json['sessionDetails'] as Map<String, dynamic>? ?? {};
    final movie = json['movieDetails'] as Map<String, dynamic>? ?? {};
    final layout = json['seatLayout'] as Map<String, dynamic>? ?? {};
    final result = layout['result'] as Map<String, dynamic>? ?? {};
    final seatsRoot = result['seats'] as Map<String, dynamic>? ?? {};
    final areasJson = seatsRoot['area'] as List<dynamic>? ?? [];

    final areas = areasJson.whereType<Map<String, dynamic>>().map((area) {
      final rowsJson = area['rows'] as List<dynamic>? ?? [];
      final rows = rowsJson.whereType<Map<String, dynamic>>().map((row) {
        final rowId = row['strRowPhyID'] as String? ?? '';
        final seatsJson = row['seats'] as List<dynamic>? ?? [];
        final seats = seatsJson.whereType<Map<String, dynamic>>().map((seat) {
          return SeatCell(
            gridNum: '${seat['strGridSeatNum']}',
            seatNumber: seat['strSeatNumber'] as String? ?? '',
            status: '${seat['strSeatStatus']}',
            rowId: rowId,
          );
        }).toList();

        return SeatRow(rowId: rowId, seats: seats);
      }).toList();

      return SeatArea(
        description: area['TType_strDescription'] as String? ??
            area['strAreaDesc'] as String? ??
            'Seats',
        price: (area['Price_curPrice'] as num?)?.toDouble() ?? 0,
        rows: rows,
      );
    }).toList();

    return SeatLayoutData(
      areas: areas,
      cinemaName: session['Cinema_strName'] as String? ?? '',
      screenName: session['Screen_strName'] as String? ?? '',
      showTime: DateTime.parse(
        session['Session_dtmRealShow'] as String? ??
            DateTime.now().toIso8601String(),
      ),
      movieTitle: movie['Film_strTitle'] as String? ?? '',
      movieImagePath: movie['image_path_1'] as String? ?? '',
      sessionId: session['Session_lngSessionId'] as int? ?? 0,
      cinemaId: session['Cinema_strID'] as String? ?? '',
    );
  }
}