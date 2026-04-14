class Incidencia {
  final String id;
  final String categoria;
  final String descripcion;
  final String estado; // Pendiente, En proceso, Resuelta
  final DateTime fecha;
  final String? fotoUrl;

  Incidencia({
    required this.id,
    required this.categoria,
    required this.descripcion,
    required this.estado,
    required this.fecha,
    this.fotoUrl,
  });
}