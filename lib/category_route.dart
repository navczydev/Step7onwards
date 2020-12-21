// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:solution_07_backdrop/api.dart';

import 'backdrop.dart';
import 'category.dart';
import 'category_tile.dart';
import 'unit.dart';
import 'unit_converter.dart';

/// Category Route (screen).
///
/// This is the 'home' screen of the Unit Converter. It shows a header and
/// a list of [Categories].
///
/// While it is named CategoryRoute, a more apt name would be CategoryScreen,
/// because it is responsible for the UI at the route's destination.
class CategoryRoute extends StatefulWidget {
  const CategoryRoute();

  @override
  _CategoryRouteState createState() => _CategoryRouteState();
}

class _CategoryRouteState extends State<CategoryRoute> {
  Category _defaultCategory;
  Category _currentCategory;
  final _categories = <Category>[];
  static const _icons = <IconData>[
    Icons.ac_unit,
    Icons.access_time_outlined,
    Icons.calculate,
    Icons.money,
    Icons.zoom_out_map,
    Icons.ad_units,
    Icons.zoom_out_sharp,
    Icons.account_balance,
  ];

  static const _baseColors = <ColorSwatch>[
    ColorSwatch(0xFFFFD28E, {
      'highlight': Color(0xFFFFD28E),
      'splash': Color(0xFFFFA41C),
    }),
    ColorSwatch(0xFFEAD37E, {
      'highlight': Color(0xFFEAD37E),
      'splash': Color(0xFFFFE070),
    }),
    ColorSwatch(0xFFCE9A9A, {
      'highlight': Color(0xFFCE9A9A),
      'splash': Color(0xFFF94D56),
      'error': Color(0xFF912D2D),
    }),
  ];

  // wait for our JSON asset to be loaded in (async).
  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    // We have static unit conversions located in our
    // assets/data/regular_units.json
    if (_categories.isEmpty) {
      await _retrieveLocalCategories();
      await _retrieveApiCategory();
    }
  }

  /// Retrieves a list of [Categories] and their [Unit]s
  Future<void> _retrieveLocalCategories() async {
    // Consider omitting the types for local variables. For more details on Effective
    // Dart Usage, see https://www.dartlang.org/guides/language/effective-dart/usage
    final json = DefaultAssetBundle.of(context)
        .loadString('assets/data/regular_units.json');
    final data = JsonDecoder().convert(await json);
    if (data is! Map) {
      throw ('Data retrieved from API is not a Map');
    }
    var categoryIndex = 0;
    data.keys.forEach((key) {
      print('Key is $key - Content ${data[key]}');
      final List<Unit> units =
          data[key].map<Unit>((dynamic data) => Unit.fromJson(data)).toList();
      String iconName = key.toString().toLowerCase();
      iconName = iconName.replaceAll(' ', '_');
      if (iconName == "energy") {
        iconName = 'currency';
      }
      var category = Category(
        name: key,
        units: units,
        color: _baseColors[Random().nextInt(3)],
        iconLocation: "assets/icons/$iconName.png",
      );
      setState(() {
        if (categoryIndex == 0) {
          _defaultCategory = category;
        }
        _categories.add(category);
      });
      categoryIndex += 1;
    });
  }

  /// Retrieves a [Category] and its [Unit]s from an API on the web
  Future<void> _retrieveApiCategory() async {
    final api = Api();
    final jsonUnits = await api.getUnits(apiCategory['route']);
    // If the API errors out or we have no internet connection, this category
    // remains in placeholder mode (disabled)
    if (jsonUnits != null) {
      final units = <Unit>[];
      for (var unit in jsonUnits) {
        units.add(Unit.fromJson(unit));
      }
      setState(() {
        _categories.removeLast();
        _categories.add(Category(
          name: apiCategory['name'],
          units: units,
          color: _baseColors.last,
          iconLocation: "assets/icons/currency.png",
        ));
      });
    }
  }

  /// Function to call when a [Category] is tapped.
  void _onCategoryTap(Category category) {
    setState(() {
      _currentCategory = category;
    });
  }

  /// Makes the correct number of rows for the list view.
  ///
  /// For portrait, we use a [ListView].
  Widget _buildCategoryWidgets(Orientation orientation) {
    if (orientation == Orientation.portrait) {
      return ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          return CategoryTile(
            category: _categories[index],
            onTap: _onCategoryTap,
          );
        },
        itemCount: _categories.length,
      );
    } else {
      return GridView.builder(
        itemCount: _categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 0.5,
            mainAxisSpacing: 0.5,
            childAspectRatio: 3.0),
        itemBuilder: (BuildContext context, int index) {
          return CategoryTile(
            category: _categories[index],
            onTap: _onCategoryTap,
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_categories.isEmpty) {
      return Center(
        child: Container(
          height: 180.0,
          width: 180.0,
          child: CircularProgressIndicator(),
        ),
      );
    }
    final listView = Padding(
      padding: EdgeInsets.only(
        left: 8.0,
        right: 8.0,
        bottom: 48.0,
      ),
      child: _buildCategoryWidgets(MediaQuery.of(context).orientation),
    );

    return Backdrop(
      currentCategory:
          _currentCategory == null ? _defaultCategory : _currentCategory,
      frontPanel: _currentCategory == null
          ? UnitConverter(category: _defaultCategory)
          : UnitConverter(category: _currentCategory),
      backPanel: listView,
      frontTitle: Text('Unit Converter'),
      backTitle: Text('Select a Category'),
    );
  }
}
