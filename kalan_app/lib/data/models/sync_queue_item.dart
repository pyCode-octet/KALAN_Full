class SyncQueueItem {
  final int? id;
  final String action;
  final String payload;
  final int timestamp;
  final int retryCount;
  final String status;
  final DateTime createdAt;

  SyncQueueItem({
    this.id,
    required this.action,
    required this.payload,
    required this.timestamp,
    this.retryCount = 0,
    this.status = 'pending',
    required this.createdAt,
  });

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) => SyncQueueItem(
        id: map['id'],
        action: map['action'],
        payload: map['payload'],
        timestamp: map['timestamp'],
        retryCount: map['retry_count'] ?? 0,
        status: map['status'] ?? 'pending',
        createdAt: DateTime.parse(map['created_at']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'action': action,
        'payload': payload,
        'timestamp': timestamp,
        'retry_count': retryCount,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };
}
