class SosCreatePayload {
  const SosCreatePayload({this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toMap() => {
    if (latitude != null && longitude != null)
      ...{'latitude': latitude, 'longitude': longitude},
  };
}

class SosCreatedEvent {
  const SosCreatedEvent({required this.id, required this.deliveryStatus});

  final String id;
  final String deliveryStatus;

  factory SosCreatedEvent.fromMap(Map<String, dynamic> data) => SosCreatedEvent(
    id: data['id'] as String,
    deliveryStatus: data['delivery_status'] as String,
  );
}
