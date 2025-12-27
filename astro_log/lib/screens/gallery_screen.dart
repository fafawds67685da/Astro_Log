import 'package:flutter/material.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Telescope Gallery'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'James Webb'),
              Tab(text: 'Hubble'),
              Tab(text: 'Chandra'),
              Tab(text: 'Spitzer'),
              Tab(text: 'My Telescope'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TelescopeTab(name: 'James Webb'),
            _TelescopeTab(name: 'Hubble'),
            _TelescopeTab(name: 'Chandra'),
            _TelescopeTab(name: 'Spitzer'),
            _TelescopeTab(name: 'My Telescope'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add_photo_alternate),
        ),
      ),
    );
  }
}

class _TelescopeTab extends StatelessWidget {
  final String name;
  
  const _TelescopeTab({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library, size: 80, color: Colors.blue),
          SizedBox(height: 16),
          Text('$name Gallery', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }
}
