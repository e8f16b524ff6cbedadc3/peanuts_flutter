import 'dart:async';
import 'package:flutter/material.dart' hide Element;

import 'components/category.dart';

class MyApp extends StatelessWidget {
  final Future<Map<String, String>> categories;

  MyApp({Key key, this.categories}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '中国花生价格行情',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CategoriesWidget(categories: categories),
    );
  }
}

void main() {
  runApp(MyApp(categories: fetchCategories()));
}
