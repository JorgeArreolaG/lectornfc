import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final int price;
  final IconData icon;
  final int count;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  const ProductCard({
    required this.name,
    required this.price,
    required this.icon,
    required this.count,
    required this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            SizedBox(height: 10),
            Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text('\$$price', style: TextStyle(color: Colors.green)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (count > 0)
                  IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: onRemove,
                  ),
                ElevatedButton(
                  onPressed: onAdd,
                  child: Text(count == 0 ? 'Agregar' : 'Cantidad: $count'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
