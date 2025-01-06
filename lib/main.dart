import 'package:flutter/material.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Art Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 175, 108, 135),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Art Studio'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    ColorMixer(),
    PaletteGenerator(),
    DataTablesPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: _widgetOptions[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.color_lens),
            label: 'Color Mixer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.palette),
            label: 'Palette Generator',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_chart),
            label: 'colors',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<void> saveLikedColor(String hexColor) async {
    final response = await http.post(
      Uri.parse('$baseUrl/save_liked_color.php'),
      body: json.encode({'hexColor': hexColor}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save color');
    }
  }

  Future<List<String>> getLikedColors() async {
    final response = await http.get(Uri.parse('$baseUrl/get_liked_colors.php'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return List<String>.from(data.map((color) => color['hexColor'] as String));
    } else {
      throw Exception('Failed to load liked colors');
    }
  }

  Future<List<List<String>>> getPalettes() async {
    final response = await http.get(Uri.parse('$baseUrl/get_palettes.php'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map<List<String>>((palette) {
        return [
          palette['color1'] as String,
          palette['color2'] as String,
          palette['color3'] as String,
          palette['color4'] as String,
          palette['color5'] as String,
        ];
      }).toList();
    } else {
      throw Exception('Failed to load palettes');
    }
  }
}

class PaletteGenerator extends StatefulWidget {
  const PaletteGenerator({super.key});

  @override
  State<PaletteGenerator> createState() => _PaletteGeneratorState();
}

class _PaletteGeneratorState extends State<PaletteGenerator> {
  List<String> generatedPalette = [];
  final ApiService apiService = ApiService(baseUrl: 'http://art-studio-project.atwebpages.com');

  void generateNewPalette() async {
    try {
      final fetchedPalettes = await apiService.getPalettes();
      if (fetchedPalettes.isNotEmpty) {
        setState(() {
          generatedPalette = fetchedPalettes[Random().nextInt(fetchedPalettes.length)];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No palettes available.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch palettes.')),
      );
    }
  }

  void copyToClipboard(String colorHex) {
    Clipboard.setData(ClipboardData(text: colorHex)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied to clipboard: $colorHex')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          if (generatedPalette.isNotEmpty) ...[
            Text('Generated Palette:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            ...generatedPalette.map((color) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    color: Color(int.parse('0xFF${color.replaceAll('#', '')}')),
                  ),
                  const SizedBox(width: 8),
                  Text(color, style: const TextStyle(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => copyToClipboard(color),
                  ),
                ],
              );
            }).toList(),
          ],
          ElevatedButton(
            onPressed: generateNewPalette,
            child: const Text('Generate palette'),
          ),
        ],
      ),
    );
  }
}

class ColorMixer extends StatefulWidget {
  const ColorMixer({super.key});

  @override
  State<ColorMixer> createState() => _ColorMixerState();
}

class _ColorMixerState extends State<ColorMixer> {
  List<String> likedColors = [];
  final ApiService apiService = ApiService(baseUrl: 'http://art-studio-project.atwebpages.com');

  double red = 0;
  double green = 0;
  double blue = 0;

  @override
  void initState() {
    super.initState();
    fetchLikedColors();
  }

  void fetchLikedColors() async {
    try {
      final fetchedColors = await apiService.getLikedColors();
      setState(() {
        likedColors = fetchedColors;
      });
    } catch (e) {
      print(e);
    }
  }

  String rgbToHex(double red, double green, double blue) {
    String redHex = red.toInt().toRadixString(16).padLeft(2, '0');
    String greenHex = green.toInt().toRadixString(16).padLeft(2, '0');
    String blueHex = blue.toInt().toRadixString(16).padLeft(2, '0');
    return redHex + greenHex + blueHex;
  }

  void likeColor() async {
    String hex = rgbToHex(red, green, blue);
    if (!likedColors.contains(hex)) {
      await apiService.saveLikedColor(hex);
      setState(() {
        likedColors.add(hex);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Liked color: #$hex'),
          duration: const Duration(seconds: 2),
        ),
      );
      fetchLikedColors();
    }
  }

  @override
  Widget build(BuildContext context) {
    String hexColor = rgbToHex(red, green, blue);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color.fromRGBO(red.toInt(), green.toInt(), blue.toInt(), 1),
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          const SizedBox(height: 16),
          Text('Red: ${red.toInt()}'),
          Slider(
            value: red,
            min: 0,
            max: 255,
            activeColor: Colors.red,
            onChanged: (value) {
              setState(() {
                red = value;
              });
            },
          ),
          Text('Green: ${green.toInt()}'),
          Slider(
            value: green,
            min: 0,
            max: 255,
            activeColor: Colors.green,
            onChanged: (value) {
              setState(() {
                green = value;
              });
            },
          ),
          Text('Blue: ${blue.toInt()}'),
          Slider(
            value: blue,
            min: 0,
            max: 255,
            activeColor: Colors.blue,
            onChanged: (value) {
              setState(() {
                blue = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'HEX: #$hexColor',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: likeColor,
            icon: const Icon(Icons.favorite, color: Colors.red),
            label: const Text('Like Color'),
          ),
          const Text(
            'Liked Colors:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: likedColors.length,
              itemBuilder: (context, index) {
                final colorHex = likedColors[index];
                return ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(int.parse('0xFF${colorHex.replaceAll('#', '')}')),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  title: Text(
                    '#$colorHex',
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DataTablesPage extends StatefulWidget {
  const DataTablesPage({super.key});

  @override
  State<DataTablesPage> createState() => _DataTablesPageState();
}

class _DataTablesPageState extends State<DataTablesPage> {
  List<dynamic> likedColorsData = [];
  List<dynamic> palettesData = [];
  final ApiService apiService = ApiService(baseUrl: 'http://art-studio-project.atwebpages.com');

  @override
  void initState() {
    super.initState();
    fetchDataTables();
  }

  void fetchDataTables() async {
    try {
      // Fetch liked colors
      final colorsResponse = await http.get(Uri.parse('${apiService.baseUrl}/get_liked_colors.php'));
      if (colorsResponse.statusCode == 200) {
        setState(() {
          likedColorsData = json.decode(colorsResponse.body);
        });
      } else {
        throw Exception('Failed to load liked colors');
      }

      // Fetch palettes
      final palettesResponse = await http.get(Uri.parse('${apiService.baseUrl}/display_palettes.php'));
      if (palettesResponse.statusCode == 200) {
        setState(() {
          palettesData = json.decode(palettesResponse.body);
        });
      } else {
        throw Exception('Failed to load palettes');
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch data tables.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text('Available color:', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Display Liked Colors
          Text('Liked Colors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: likedColorsData.length,
              itemBuilder: (context, index) {
                final color = likedColorsData[index]['hexColor'] ?? 'No Color';
                return ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(int.parse('0xFF${color.replaceAll('#', '')}')),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  title: Text('#${color}'),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Display Palettes
          Text('Available Palettes:', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: palettesData.length,
              itemBuilder: (context, index) {
                final palette = palettesData[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Palette ${index + 1}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 1; i <= 5; i++) // through 5 colors
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,

                                decoration: BoxDecoration(
                                  color: Color(int.parse('0xFF${palette['color$i']?.replaceAll('#', '')}')),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(palette['color$i'] ?? 'No Color', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16), // Space between palettes
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}