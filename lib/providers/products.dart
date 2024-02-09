import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop_app/models/http_exception.dart';

import './product.dart';

class Products with ChangeNotifier {
  List<Product> _items = [
    /*Product(
      id: 'p1',
      title: 'Red Shirt',
      description: 'A red shirt - it is pretty red!',
      price: 29.99,
      imageUrl:
          'https://cdn.pixabay.com/photo/2016/10/02/22/17/red-t-shirt-1710578_1280.jpg',
    ),
    Product(
      id: 'p2',
      title: 'Trousers',
      description: 'A nice pair of trousers.',
      price: 59.99,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Trousers%2C_dress_%28AM_1960.022-8%29.jpg/512px-Trousers%2C_dress_%28AM_1960.022-8%29.jpg',
    ),
    Product(
      id: 'p3',
      title: 'Yellow Scarf',
      description: 'Warm and cozy - exactly what you need for the winter.',
      price: 19.99,
      imageUrl:
          'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
    ),
    Product(
      id: 'p4',
      title: 'A Pan',
      description: 'Prepare any meal you want.',
      price: 49.99,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Cast-Iron-Pan.jpg/1024px-Cast-Iron-Pan.jpg',
    ),*/
  ];
  // var _showFavoritesOnly = false;
  String? token;
  String? userId;
  Products(this.token, this.userId, this._items);

  List<Product> get items {
    // if (_showFavoritesOnly) {
    //   return _items.where((prodItem) => prodItem.isFavorite).toList();
    // }
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((prodItem) => prodItem.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<void> getAndFetchData({bool filterByUser = false}) async {
    final filter = filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
    var url = Uri.parse(
        'https://flutter-update-cb6af-default-rtdb.firebaseio.com/products.json?auth=$token&$filter');
    try {
      final respons = await http.get(url);
      final resevedData = json.decode(respons.body) as Map<String, dynamic>?;
      if (resevedData == null) {
        return;
      }
      url = Uri.parse(
          'https://flutter-update-cb6af-default-rtdb.firebaseio.com/userFavorits/$userId.json?auth=$token');
      final responsfavorits = await http.get(url);
      final favorits = json.decode(responsfavorits.body);

      List<Product> items = [];
      resevedData.forEach((prodId, data) {
        items.add(
          Product(
            id: prodId,
            title: data['title'],
            description: data['description'],
            price: data['price'],
            imageUrl: data['imageUrl'],
            isFavorite: favorits == null || favorits[prodId] == null
                ? false
                : favorits[prodId],
          ),
        );
      });
      _items = items;
      notifyListeners();
    } catch (error) {
      //print(error);
      rethrow;
    }
  }

  Future<void> addProduct(Product product) {
    final url = Uri.parse(
        'https://flutter-update-cb6af-default-rtdb.firebaseio.com/products.json?auth=$token');

    return http
        .post(
      url,
      body: json.encode({
        'title': product.title,
        'description': product.description,
        'imageUrl': product.imageUrl,
        'price': product.price,
        'creatorId': userId,
      }),
    )
        .then((response) {
      final newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        id: json.decode(response.body)['name'],
      );
      _items.add(newProduct);
      // _items.insert(0, newProduct); // at the start of the list
      notifyListeners();
    });
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);

    if (prodIndex >= 0) {
      final url = Uri.parse(
          'https://flutter-update-cb6af-default-rtdb.firebaseio.com/products/$id.json?auth=$token');
      await http.patch(
        url,
        body: json.encode({
          'title': newProduct.title,
          'description': newProduct.description,
          'imageUrl': newProduct.imageUrl,
          'price': newProduct.price,
        }),
      );

      _items[prodIndex] = newProduct;
      notifyListeners();
    } else {
      // print('...');
    }
  }

  Future<void> deleteProduct(String id) async {
    var url = Uri.parse(
        'https://flutter-update-cb6af-default-rtdb.firebaseio.com/products/$id.json?auth=$token');

    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    Product? existingProduct = _items[existingProductIndex];
    _items.removeAt(existingProductIndex);
    notifyListeners();

    final response = await http.delete(url);
    url = Uri.parse(
        'https://flutter-update-cb6af-default-rtdb.firebaseio.com/userFavorits/$userId/$id.json?auth=$token');
    await http.delete(url);
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete product.');
    }
    existingProduct = null;
  }
}
