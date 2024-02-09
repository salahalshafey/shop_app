import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop_app/models/http_exception.dart';

import './cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    required this.id,
    required this.amount,
    required this.products,
    required this.dateTime,
  });
}

class Orders with ChangeNotifier {
  List<OrderItem> _orders = [];
  final String? token;
  final String? userId;
  Orders(this.token, this.userId, this._orders);

  List<OrderItem> get orders {
    return [..._orders];
  }

  Future<void> getAndFetchData() async {
    final url = Uri.parse(
        'https://flutter-update-cb6af-default-rtdb.firebaseio.com/orders/$userId.json?auth=$token');
    try {
      final respons = await http.get(url);
      final resevedData = json.decode(respons.body) as Map<String, dynamic>?;
      if (resevedData == null) {
        return;
      }

      List<OrderItem> items = [];
      resevedData.forEach((prodId, data) {
        final cartProducts = data['products'] as List<dynamic>;
        items.add(OrderItem(
          id: prodId,
          amount: data['amount'],
          dateTime: DateTime.parse(data['dateTime']),
          products: cartProducts
              .map((cp) => CartItem(
                    id: cp['id'],
                    title: cp['title'],
                    quantity: cp['quantity'],
                    price: cp['price'],
                  ))
              .toList(),
        ));
      });
      _orders = items.reversed.toList();
      notifyListeners();
    } catch (error) {
      // print(error);
      rethrow;
    }
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    if (cartProducts.isEmpty) {
      return;
    }

    final url = Uri.parse(
        'https://flutter-update-cb6af-default-rtdb.firebaseio.com/orders/$userId.json?auth=$token');
    final timeStamp = DateTime.now();
    http.Response? theResponse;

    try {
      final respons = await http.post(
        url,
        body: json.encode({
          'amount': total,
          'dateTime': timeStamp.toIso8601String(),
          'products': cartProducts
              .map(
                (cp) => {
                  'id': cp.id,
                  'title': cp.title,
                  'quantity': cp.quantity,
                  'price': cp.price,
                },
              )
              .toList(),
        }),
      );
      theResponse = respons;
    } catch (error) {
      throw HttpException('Some thing went wrong!');
    }

    _orders.insert(
      0,
      OrderItem(
        id: json.decode(theResponse.body)['name'],
        amount: total,
        dateTime: timeStamp,
        products: cartProducts,
      ),
    );
    notifyListeners();
  }
}
