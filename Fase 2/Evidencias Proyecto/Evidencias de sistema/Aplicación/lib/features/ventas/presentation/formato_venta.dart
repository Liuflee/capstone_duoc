String precioVenta(double precio) =>
    '\$${precio.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}';
