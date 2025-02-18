import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'dart:js' as js;
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'dart:ui_web' as ui_web;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      title: 'Image Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ImageViewerScreen(),
    );
  }
}

class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({Key? key}) : super(key: key);

  @override
  _ImageViewerScreenState createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  final TextEditingController _urlController = TextEditingController();
  String _currentUrl = '';
  bool _isMenuOpen = false;
  bool _isFullScreen = false;
  late final String _viewType =
      'html-element-${DateTime.now().millisecondsSinceEpoch}';

  // Register JavaScript functions
  void _registerJsFunctions() {
    // Define JS functions for fullscreen control
    _injectJavaScript();

    // Register HTML view factory for the image
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final element = html.DivElement()
          ..id = 'html-container'
          ..style.width = '100%'
          ..style.height = '100%';

        if (_currentUrl.isNotEmpty) {
          final imgElement = html.ImageElement()
            ..src = _currentUrl
            ..style.maxWidth = '100%'
            ..style.maxHeight = '100%'
            ..style.objectFit = 'contain';

          // Add double-click listener for fullscreen
          imgElement.onDoubleClick.listen((_) {
            _toggleFullScreen();
          });

          element.children.add(imgElement);
        }

        return element;
      },
    );
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _registerJsFunctions();
    }
  }

  void _loadImage() {
    if (_urlController.text.trim().isNotEmpty) {
      setState(() {
        _currentUrl = _urlController.text.trim();
      });
    }
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _toggleFullScreen() {
    if (_isFullScreen) {
      js.context.callMethod('exitFullScreenMode');
    } else {
      js.context.callMethod('enterFullScreenMode');
    }
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Main Content
          Column(
            children: [
              // URL Input Area
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          hintText: 'Enter image URL...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12.0),
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.blue,
                      child: InkWell(
                        onTap: _loadImage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 12.0),
                          child: const Icon(Icons.arrow_forward,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Image Display Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Center(
                      child: kIsWeb && _currentUrl.isNotEmpty
                          ? HtmlElementView(
                              viewType: _viewType,
                            )
                          : const Text('No image loaded'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
            ],
          ),

          // Plus Button
          Positioned(
            right: 20.0,
            bottom: 20.0,
            child: FloatingActionButton(
              onPressed: _toggleMenu,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),

          // Context Menu
          if (_isMenuOpen)
            Positioned(
              right: 20.0,
              bottom: 85.0,
              child: Card(
                elevation: 8.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        _toggleFullScreen();
                        _toggleMenu();
                      },
                      child: Container(
                        width: 180.0,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 20.0),
                        child: Text(_isFullScreen
                            ? 'Exit fullscreen'
                            : 'Enter fullscreen'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Overlay
          if (_isMenuOpen)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: false,
                child: GestureDetector(
                  onTap: _toggleMenu,
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}

// JavaScript functions to be called from Dart
void _injectJavaScript() {
  js.context['enterFullScreenMode'] = () {
    final element = js.context['document']['documentElement'];
    if (element['requestFullscreen'] != null) {
      element.callMethod('requestFullscreen');
    } else if (element['mozRequestFullScreen'] != null) {
      element.callMethod('mozRequestFullScreen');
    } else if (element['webkitRequestFullscreen'] != null) {
      element.callMethod('webkitRequestFullscreen');
    } else if (element['msRequestFullscreen'] != null) {
      element.callMethod('msRequestFullscreen');
    }
  };

  js.context['exitFullScreenMode'] = () {
    final document = js.context['document'];
    if (document['exitFullscreen'] != null) {
      document.callMethod('exitFullscreen');
    } else if (document['mozCancelFullScreen'] != null) {
      document.callMethod('mozCancelFullScreen');
    } else if (document['webkitExitFullscreen'] != null) {
      document.callMethod('webkitExitFullscreen');
    } else if (document['msExitFullscreen'] != null) {
      document.callMethod('msExitFullscreen');
    }
  };
}
