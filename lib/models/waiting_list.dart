class WaitingList {
  final String? id;
  final String storeId;
  final String waitingId;
  final int queueNumber;
  final String customerName;
  final int partySize;
  final String nationality;
  final DateTime registrationTime;  final String? contact;
  final String status;
  final String? notes;
  final DateTime? calledTime;
  final DateTime? entryTime;

  WaitingList({
    this.id,
    required this.storeId,
    required this.waitingId,
    required this.queueNumber,
    required this.customerName,
    required this.partySize,
    required this.nationality,
    required this.registrationTime,
    this.contact,
    required this.status,
    this.notes,
    this.calledTime,
    this.entryTime,
  });
  factory WaitingList.fromJson(Map<String, dynamic> json) {
    try {
      return WaitingList(
        id: json['id'],
        storeId: json['store_id'] ?? '',
        waitingId: json['waiting_id'] ?? '',
        queueNumber: json['queue_number'] ?? 0,
        customerName: json['customer_name'] ?? '',
        partySize: json['party_size'] ?? 1,
        nationality: json['nationality'] ?? '',
        registrationTime: json['registration_time'] != null 
            ? DateTime.parse(json['registration_time']) 
            : DateTime.now(),
        contact: json['contact'],
        status: json['status'] ?? 'waiting',
        notes: json['notes'],
        calledTime: json['called_time'] != null ? DateTime.parse(json['called_time']) : null,
        entryTime: json['entry_time'] != null ? DateTime.parse(json['entry_time']) : null,
      );
    } catch (e) {
      print('Error parsing JSON: $e');
      print('Received JSON: $json');
      rethrow;
    }
  }

  // 오늘 마지막 입장 시간을 구하는 static 메서드
  static DateTime? getLastEntryTime(List<WaitingList> waitingList) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    DateTime? lastEntryTime;
    for (var item in waitingList) {
      if (item.entryTime != null) {
        final entryDate = DateTime(item.entryTime!.year, item.entryTime!.month, item.entryTime!.day);
        if (entryDate.isAtSameMomentAs(today)) {
          if (lastEntryTime == null || item.entryTime!.isAfter(lastEntryTime)) {
            lastEntryTime = item.entryTime;
          }
        }
      }
    }
    return lastEntryTime;
  }
}