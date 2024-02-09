import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart.dart' show Cart;
import '../widgets/cart_item.dart';
import '../providers/orders.dart';

class CartScreen extends StatelessWidget {
  static const routeName = '/cart';

  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: Column(
        children: <Widget>[
          Card(
            margin: const EdgeInsets.all(15),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 20),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(
                      '\$${cart.totalAmount.toStringAsFixed(2)}',
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  _OrderButtonState(cart: cart)
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (ctx, i) => CartItem(
                cart.items.values.toList()[i].id,
                cart.items.keys.toList()[i],
                cart.items.values.toList()[i].price,
                cart.items.values.toList()[i].quantity,
                cart.items.values.toList()[i].title,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _OrderButtonState extends StatefulWidget {
  const _OrderButtonState({
    Key? key,
    required this.cart,
  }) : super(key: key);

  final Cart cart;

  @override
  State<_OrderButtonState> createState() => _OrderButtonStateState();
}

class _OrderButtonStateState extends State<_OrderButtonState> {
  var _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            child: const CircularProgressIndicator(),
          )
        : TextButton(
            child: const Text('ORDER NOW'),
            onPressed: widget.cart.itemCount <= 0
                ? null
                : () async {
                    setState(() {
                      _isLoading = true;
                    });

                    await Provider.of<Orders>(context, listen: false)
                        .addOrder(
                      widget.cart.items.values.toList(),
                      widget.cart.totalAmount,
                    )
                        .then((_) {
                      widget.cart.clear();
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Some thing went wrong!',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    });

                    setState(() {
                      _isLoading = false;
                    });
                  },
          );
  }
}
