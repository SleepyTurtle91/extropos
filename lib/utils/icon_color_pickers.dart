import 'package:flutter/material.dart';

class IconColorPickers {
  static Future<IconData?> showIconPicker(
    BuildContext context,
    IconData current,
  ) async {
    final icons = [
      Icons.shopping_bag,
      Icons.local_cafe,
      Icons.restaurant,
      Icons.cake,
      Icons.local_pizza,
      Icons.icecream,
      Icons.lunch_dining,
      Icons.breakfast_dining,
      Icons.dinner_dining,
      Icons.liquor,
      Icons.local_bar,
      Icons.fastfood,
      Icons.coffee,
      Icons.wine_bar,
      Icons.ramen_dining,
      Icons.emoji_food_beverage,
    ];

    return showDialog<IconData>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Icon'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () => Navigator.pop(context, icons[index]),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: icons[index] == current
                          ? const Color(0xFF2563EB)
                          : Colors.grey,
                      width: icons[index] == current ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icons[index], size: 32),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static Future<Color?> showColorPicker(
    BuildContext context,
    Color current,
  ) async {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
    ];

    return showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () => Navigator.pop(context, colors[index]),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors[index] == current
                          ? Colors.black
                          : Colors.grey,
                      width: colors[index] == current ? 3 : 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
