import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/screens/product_image_screen.dart';

import '../screens/edit_product_screen.dart';
import '../providers/products.dart';

class UserProductItem extends StatelessWidget {
  final String id;
  final String title;
  final String imageUrl;

  const UserProductItem(this.id, this.title, this.imageUrl, {Key? key})
      : super(key: key);

  void _confirmDeletion(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: Text(
          'Do you want to remove "$title" from the products?',
        ),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: <Widget>[
          TextButton(
            child: const Text('No'),
            onPressed: () {
              Navigator.of(ctx).pop(true);
            },
          ),
          TextButton(
            child: const Text('Yes'),
            onPressed: () async {
              await Provider.of<Products>(ctx, listen: false)
                  .deleteProduct(id)
                  .catchError((error) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Deleting failed!',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              });
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showImageInDialog(BuildContext ctx) {
    showDialog<bool>(
      context: ctx,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).popAndPushNamed(
          ProductImageScreen.routeName,
          arguments: id,
        ),
        child: Dialog(
          child: SizedBox(
            height: 300,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      leading: GestureDetector(
        onTap: () => _showImageInDialog(context),
        child: CircleAvatar(
          backgroundImage: NetworkImage(imageUrl),
        ),
      ),
      trailing: SizedBox(
        width: 100,
        child: Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context)
                    .pushNamed(EditProductScreen.routeName, arguments: id);
              },
              color: Theme.of(context).colorScheme.primary,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDeletion(context),
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}
