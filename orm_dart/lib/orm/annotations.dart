class Table {
  final String name;
  const Table(this.name);
}

class Column {
  final String name;
  final bool primaryKey;
  const Column(this.name, {this.primaryKey = false});
}

