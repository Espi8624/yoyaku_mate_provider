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
  final DateTime? calledTime;
  final DateTime? entryTime;
  final String? notes;
  final int estimatedWaitTime;
  final List<MenuItem> menuItems;

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
    this.calledTime,
    this.entryTime,
    this.notes,
    required this.estimatedWaitTime,
    this.menuItems = const [],
  });

  WaitingList copyWith({
    String? id,
    String? storeId,
    String? waitingId,
    int? queueNumber,
    int? partySize,
    String? nationality,
    DateTime? registrationTime,
    String? contact,
    String? status,
    DateTime? calledTime,
    DateTime? entryTime,
    String? notes,
    int? estimatedWaitTime,
    List<MenuItem>? menuItems,
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
      calledTime: calledTime ?? this.calledTime,
      entryTime: entryTime ?? this.entryTime,
      notes: notes ?? this.notes,
      estimatedWaitTime: estimatedWaitTime ?? this.estimatedWaitTime,
      menuItems: menuItems ?? this.menuItems,
    );
  }

  factory WaitingList.fromJson(Map<String, dynamic> json) {
    return WaitingList(
      id: json['id'],
      storeId: json['store_id'] ?? '',
      waitingId: json['waiting_id'] ?? '',
      queueNumber: json['queue_number'] ?? 0,
      partySize: json['party_size'] ?? 0,
      nationality: json['nationality'] ?? '',
      registrationTime: DateTime.parse(
          json['registration_time'] ?? DateTime.now().toIso8601String()),
      contact: json['contact'],
      status: json['status'] ?? 'waiting',
      calledTime: json['called_time'] != null && json['called_time'] != ''
          ? DateTime.parse(json['called_time'])
          : null,
      entryTime: json['entry_time'] != null && json['entry_time'] != ''
          ? DateTime.parse(json['entry_time'])
          : null,
      notes: json['notes'],
      estimatedWaitTime: json['estimated_wait_time'] ?? 0,
      menuItems: (json['menu_items'] as List<dynamic>?)
              ?.map((e) => MenuItem.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'store_id': storeId,
        'waiting_id': waitingId,
        'queue_number': queueNumber,
        'party_size': partySize,
        'nationality': nationality,
        'registration_time': registrationTime.toIso8601String(),
        'contact': contact,
        'status': status,
        'called_time': calledTime?.toIso8601String(),
        'entry_time': entryTime?.toIso8601String(),
        'notes': notes,
        'estimated_wait_time': estimatedWaitTime,
        'menu_items': menuItems.map((e) => e.toJson()).toList(),
      };
}

class MenuItem {
  final String menuId;
  final String name;
  final int quantity;
  final String? options;

  MenuItem({
    required this.menuId,
    required this.name,
    required this.quantity,
    this.options,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      menuId: json['menu_id'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      options: json['options'],
    );
  }

  Map<String, dynamic> toJson() => {
        'menu_id': menuId,
        'name': name,
        'quantity': quantity,
        'options': options,
      };
}
