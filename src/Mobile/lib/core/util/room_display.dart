/// Backend [RoomType]: None=0, Public=1, Private=2
String roomTypeLabelTr(dynamic value) {
  final n = switch (value) {
    int v => v,
    num v => v.toInt(),
    String v => int.tryParse(v.trim()),
    _ => null,
  };
  return switch (n) {
    0 => 'Belirtilmedi',
    1 => 'Herkese açık oda',
    2 => 'Özel oda',
    null => '—',
    _ => 'Oda tipi $n',
  };
}
