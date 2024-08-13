// Copyright 2024, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:firebase_data_connect_example/login.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'generated/movies.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter DataConnect Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Login(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class DataConnectWidget extends StatefulWidget {
  const DataConnectWidget({super.key});
  @override
  State<DataConnectWidget> createState() => _DataConnectWidgetState();
}

class _DataConnectWidgetState extends State<DataConnectWidget> {
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  DateTime _releaseYearDate = DateTime(1920);
  List<ListMoviesMovies> _movies = [];
  double _rating = 0;

  Future<void> triggerReload() async {
    QueryRef ref = MoviesConnector.instance.listMovies.ref();

    ref.execute().ignore();
  }

  @override
  void initState() {
    super.initState();
    String host = 'localhost';
    try {
      if (Platform.isAndroid) {
        host = '10.0.2.2';
      }
    } catch (_) {}
    int port = 3628;
    FirebaseDataConnect.instanceFor(
            app: Firebase.app(),
            connectorConfig: MoviesConnector.connectorConfig)
        .useDataConnectEmulator(host, port: port);

    QueryRef<ListMoviesResponse, void> ref =
        MoviesConnector.instance.listMovies.ref();

    ref.subscribe().listen((event) {
      setState(() {
        _movies = event.data.movies;
      });
    }).onError((e) {
      if (kDebugMode) {
        _showError("Got an error: $e");
      }
    });
  }

  Future<void> initFirebase() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Flex(direction: Axis.vertical, children: [
          Flexible(
            flex: 1,
            child: TextFormField(
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: 'Name',
              ),
              controller: _titleController,
            ),
          ),
          Flexible(
              flex: 1,
              child: TextFormField(
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Genre',
                ),
                controller: _genreController,
              )),
          Flexible(
              flex: 1,
              child: RatingBar.builder(
                initialRating: 3,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  _rating = rating;
                },
              )),
          Flexible(
              flex: 1,
              child: YearPicker(
                firstDate: DateTime(1990),
                lastDate: DateTime.now(),
                selectedDate: _releaseYearDate,
                onChanged: (value) {
                  setState(() {
                    _releaseYearDate = value;
                  });
                },
              )),
          TextButton(
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all<Color>(Colors.blue),
            ),
            onPressed: () async {
              String title = _titleController.text;
              String genre = _genreController.text;
              if (title == '' || genre == '') {
                return;
              }

              MutationRef ref = MoviesConnector.instance.createMovie.ref(
                  CreateMovieVariables(
                      title, _releaseYearDate.year, genre, _rating, null));
              try {
                await ref.execute();
                triggerReload();
              } catch (e) {
                _showError("unable to create a movie: $e");
              }
            },
            child: const Text('Add Movie'),
          ),
          const Center(
            child: Text(
              "Movies",
              style: TextStyle(fontSize: 35.0),
            ),
          ),
          Expanded(
              child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => triggerReload(),
                  child: ListView(
                      scrollDirection: Axis.vertical,
                      children: _movies
                          .map((movie) => Card(
                                  child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Center(
                                  child: Text(
                                    movie.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )))
                          .toList()),
                ),
              )
            ],
          ))
        ]));
  }

  _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: SingleChildScrollView(
            child: SelectableText(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: const Center(
        child: DataConnectWidget(),
      ),
    );
  }
}
