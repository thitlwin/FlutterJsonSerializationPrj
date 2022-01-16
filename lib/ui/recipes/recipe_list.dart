import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_dropdown.dart';
import '../colors.dart';

import 'dart:convert';
import '../../network/recipe_model.dart';
import 'package:flutter/services.dart';
import '../recipe_card.dart';
import 'recipe_details.dart';

class RecipeList extends StatefulWidget {
  const RecipeList({Key? key}) : super(key: key);

  @override
  _RecipeListState createState() => _RecipeListState();
}

class _RecipeListState extends State<RecipeList> {
  static const String prefSearchKey = 'previousSearches';

  late TextEditingController searchTextController;
  final ScrollController _scrollController = ScrollController();
  List currentSearchList = [];
  int currentCount = 0;
  int currentStartPosition = 0;
  int currentEndPosition = 20;
  int pageCount = 20;
  bool hasMore = false;
  bool loading = false;
  bool inErrorState = false;
  List<String> previousSearches = <String>[];

  APIRecipeQuery? _currentRecipes1 = null;

  @override
  void initState() {
    super.initState();
    loadRecipes();
    getPreviousSearches();
    searchTextController = TextEditingController(text: '');
    _scrollController
      ..addListener(() {
        final triggerFetchMoreSize =
            0.7 * _scrollController.position.maxScrollExtent;

        if (_scrollController.position.pixels > triggerFetchMoreSize) {
          if (hasMore &&
              currentEndPosition < currentCount &&
              !loading &&
              !inErrorState) {
            setState(() {
              loading = true;
              currentStartPosition = currentEndPosition;
              currentEndPosition =
                  min(currentStartPosition + pageCount, currentCount);
            });
          }
        }
      });
  }

  @override
  void dispose() {
    searchTextController.dispose();
    super.dispose();
  }

  Future loadRecipes() async {
    // 1
    final jsonString = await rootBundle.loadString('assets/recipes1.json');
    setState(() {
      // 2
      _currentRecipes1 = APIRecipeQuery.fromJson(jsonDecode(jsonString));
    });
  }

  void savePreviousSearches() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(prefSearchKey, previousSearches);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            _buildSearchCard(),
            _buildRecipeLoader(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      elevation: 4,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0))),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            IconButton(
                onPressed: () {
                  startSearch(searchTextController.text);
                  final currentFocus = FocusScope.of(context);
                  if (!currentFocus.hasPrimaryFocus) {
                    currentFocus.unfocus();
                  }
                },
                icon: const Icon(Icons.search)),
            const SizedBox(
              width: 6.0,
            ),
            Expanded(
              child: Row(
                children: <Widget>[
                  Expanded(
                      // 3
                      child: TextField(
                    decoration: const InputDecoration(
                        border: InputBorder.none, hintText: 'Search'),
                    autofocus: false,
                    // 4
                    textInputAction: TextInputAction.done,
                    // 5
                    onSubmitted: (value) {
                      if (!previousSearches.contains(value)) {
                        previousSearches.add(value);
                        savePreviousSearches();
                      }
                    },
                    controller: searchTextController,
                  )),
                  // 6
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: lightGrey,
                    ),
                    // 7
                    onSelected: (String value) {
                      searchTextController.text = value;
                      startSearch(searchTextController.text);
                    },
                    itemBuilder: (BuildContext context) {
                      // 8
                      return previousSearches
                          .map<CustomDropdownMenuItem<String>>((String value) {
                        return CustomDropdownMenuItem<String>(
                          text: value,
                          value: value,
                          callback: () {
                            setState(() {
                              // 9
                              previousSearches.remove(value);
                              Navigator.pop(context);
                            });
                          },
                        );
                      }).toList();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void startSearch(String value) {
    // 1
    setState(() {
      // 2
      currentSearchList.clear();
      currentCount = 0;
      currentEndPosition = pageCount;
      currentStartPosition = 0;
      hasMore = true;
      value = value.trim();

      // 3
      if (!previousSearches.contains(value)) {
        // 4
        previousSearches.add(value);
        // 5
        savePreviousSearches();
      }
    });
  }

  Widget _buildRecipeLoader(BuildContext context) {
    // 1
    if (_currentRecipes1 == null || _currentRecipes1?.hits == null) {
      return Container();
    }
    // Show a loading indicator while waiting for the recipes
    return Center(
      // 2
      child: _buildRecipeCard(context, _currentRecipes1!.hits, 0),
    );
  }

  void getPreviousSearches() async {
    // 1
    final prefs = await SharedPreferences.getInstance();
    // 2
    if (prefs.containsKey(prefSearchKey)) {
      // 3
      final searches = prefs.getStringList(prefSearchKey);
      // 4
      if (searches != null) {
        previousSearches = searches;
      } else {
        previousSearches = <String>[];
      }
    }
  }

  Widget _buildRecipeCard(
      BuildContext topLevelContext, List<APIHits> hits, int index) {
    // 1
    final recipe = hits[index].recipe;
    return GestureDetector(
      onTap: () {
        Navigator.push(topLevelContext, MaterialPageRoute(
          builder: (context) {
            return const RecipeDetails();
          },
        ));
      },
      // 2
      child: recipeStringCard(recipe.image, recipe.label),
    );
  }
}
