class Book {
  final int id;
  final String title;
  final String author;
  final String? imageUrl;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.imageUrl,
  });

  // Dummy knjige za testiranje
  static List<Book> getDummyBooks() {
    return [
      Book(
        id: 1,
        title: 'The Outsiders',
        author: 'S.E. Hinton',
        imageUrl: null,
      ),
      Book(
        id: 2,
        title: "Alice's Adventures in Wonderland",
        author: 'Lewis Carroll',
        imageUrl: null,
      ),
      Book(
        id: 3,
        title: 'Tuesdays with Morrie',
        author: 'Mitch Albom',
        imageUrl: null,
      ),
      Book(
        id: 4,
        title: 'To Kill a Mockingbird',
        author: 'Harper Lee',
        imageUrl: null,
      ),
      Book(
        id: 5,
        title: '1984',
        author: 'George Orwell',
        imageUrl: null,
      ),
    ];
  }
}