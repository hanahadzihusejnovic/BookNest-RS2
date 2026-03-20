class Event {
  final int id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
  });

  static List<Event> getDummyEvents() {
  return [
    Event(
      id: 1,
      title: 'Book club session',
      description: 'Online book discussion - Theme: "The Boy In The Striped Pajamas" by John Boyne',
      dateTime: DateTime.now().add(const Duration(days: 2)),
      location: 'Online',
    ),
    Event(
      id: 2,
      title: 'Relax&Read session',
      description: 'Enjoy your free time by reserving your place at BookNest center!',
      dateTime: DateTime.now().add(const Duration(days: 5)),
      location: 'BookNest center',
    ),
    Event(
      id: 3,
      title: 'Author Meet & Greet',
      description: 'Meet your favorite author and get your books signed!',
      dateTime: DateTime.now().add(const Duration(days: 8)),
      location: 'Main Library',
    ),
    Event(
      id: 4,
      title: 'BookNest workshop',
      description: 'Creative writing workshop',
      dateTime: DateTime.now().add(const Duration(days: 7)),
      location: 'Bookstore B',
    ),
    Event(
      id: 5,
      title: 'Kids corner',
      description: 'Reading session for children',
      dateTime: DateTime.now().add(const Duration(days: 10)),
      location: 'National park',
    ),
    Event(
      id: 6,
      title: 'Poetry Night',
      description: 'Share and listen to poetry readings',
      dateTime: DateTime.now().add(const Duration(days: 12)),
      location: 'BookNest Café',
    ),
    Event(
      id: 7,
      title: 'Book Swap Event',
      description: 'Bring your old books and swap with others',
      dateTime: DateTime.now().add(const Duration(days: 15)),
      location: 'Community Center',
    ),
    Event(
      id: 8,
      title: 'Book  Event',
      description: 'Bring your old books and swap with others',
      dateTime: DateTime.now().add(const Duration(days: 15)),
      location: 'Community',
    ),
  ];
}

  String getFormattedDate() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[dateTime.weekday - 1]} - ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}pm';
  }
}