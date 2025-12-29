import 'package:flutter/material.dart';
import 'books_screen.dart';

class AcademicsScreen extends StatelessWidget {
  const AcademicsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Academics section now only shows Books by default
    // Papers and Projects are accessed via the drawer in BooksScreen
    return const BooksScreen();
  }
}
