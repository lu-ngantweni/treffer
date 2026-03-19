class Event {
  final String id;
  final String title;
  final DateTime date;
  final String? venue;
  final String? description;
  final String? imageUrl;

  Event({
    required this.id,
    required this.title,
    required this.date,
    this.venue,
    this.description,
    this.imageUrl,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      venue: json['venue'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'venue': venue,
    'description': description,
    'image_url': imageUrl,
  };

  String get formattedDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}