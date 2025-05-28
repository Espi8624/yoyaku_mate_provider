class WaitingList {
  final String? id;
  final String storeId;
  final String waitingId;
  final int queueNumber;
  final String customerName;
  final int partySize;
  final DateTime registrationTime;
  final String contact;
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
    required this.registrationTime,
    required this.contact,
    required this.status,
    this.notes,
    this.calledTime,
    this.entryTime,
  });

  factory WaitingList.fromJson(Map<String, dynamic> json) {
    return WaitingList(
      id: json['id'],
      storeId: json['store_id'],
      waitingId: json['waiting_id'],
      queueNumber: json['queue_number'],
      customerName: json['customer_name'],
      partySize: json['party_size'],
      registrationTime: DateTime.parse(json['registration_time']),
      contact: json['contact'],
      status: json['status'],
      notes: json['notes'],
      calledTime: json['called_time'] != null ? DateTime.parse(json['called_time']) : null,
      entryTime: json['entry_time'] != null ? DateTime.parse(json['entry_time']) : null,
    );
  }
}