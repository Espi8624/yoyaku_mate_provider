class WaitingList {
  final String? id;
  final String storeId;
  final String waitingId;
  final int queueNumber;
  final int partySize;
  final String nationality;
  final DateTime registrationTime;
  final String? contact;
  final String status;
  final String? notes;
  final DateTime? calledTime;
  final DateTime? entryTime;
  final DateTime? updatedAt;
  final int? estimatedWaitTime;

  WaitingList({
    this.id,
    required this.storeId,
    required this.waitingId,
    required this.queueNumber,
    required this.partySize,
    required this.nationality,
    required this.registrationTime,
    this.contact,
    required this.status,
    this.notes,
    this.calledTime,
    this.entryTime,
    this.updatedAt,
    this.estimatedWaitTime,
  });

  factory WaitingList.fromJson(Map<String, dynamic> json) {
    try {
      return WaitingList(
        id: json['id'],
        storeId: json['store_id'] ?? '',
        waitingId: json['waiting_id'] ?? '',
        queueNumber: json['queue_number'] ?? 0,
        partySize: json['party_size'] ?? 1,
        nationality: json['nationality'] ?? '',
        registrationTime: json['registration_time'] != null
            ? DateTime.parse(json['registration_time'])
            : DateTime.now(),
        contact: json['contact'],
        status: json['status'] ?? 'waiting',
        notes: json['notes'],
        calledTime: json['called_time'] != null
            ? DateTime.parse(json['called_time'])
            : null,
        entryTime: json['entry_time'] != null
            ? DateTime.parse(json['entry_time'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
        estimatedWaitTime: json['estimated_wait_time'],
      );
    } catch (e) {
      print('Error parsing JSON: $e');
      print('Received JSON: $json');
      rethrow;
    }
  }

  WaitingList copyWith({
    String? id,
    String? storeId,
    String? waitingId,
    int? queueNumber,
    String? customerName,
    int? partySize,
    String? nationality,
    DateTime? registrationTime,
    String? contact,
    String? status,
    String? notes,
    DateTime? calledTime,
    DateTime? entryTime,
    DateTime? updatedAt,
    int? estimatedWaitTime,
  }) {
    return WaitingList(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      waitingId: waitingId ?? this.waitingId,
      queueNumber: queueNumber ?? this.queueNumber,
      partySize: partySize ?? this.partySize,
      nationality: nationality ?? this.nationality,
      registrationTime: registrationTime ?? this.registrationTime,
      contact: contact ?? this.contact,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      calledTime: calledTime ?? this.calledTime,
      entryTime: entryTime ?? this.entryTime,
      updatedAt: updatedAt ?? this.updatedAt,
      estimatedWaitTime: estimatedWaitTime ?? this.estimatedWaitTime,
    );
  }

  // 下記のロジックは ViewModel へ移動
  // static DateTime? getLastEntryTime(List<WaitingList> waitingList) { ... }
}
