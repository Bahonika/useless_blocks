import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:useless_blocs/plot.dart';

void main() {
  runApp(const MyApp());
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]); // Вертикальная ориентация
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Clicker(),
    );
  }
}

var texts = <String>[];

// Цвета для фона и элементов
Color backgroundColor = Colors.white;
Color textColor = Colors.black;

bool isDarkTheme = false;

class Clicker extends StatefulWidget {
  const Clicker({Key? key}) : super(key: key);

  @override
  _ClickerState createState() => _ClickerState();
}

class _ClickerState extends State<Clicker> with TickerProviderStateMixin {
  Random rnd = Random();

  late double width; // Ширина блока
  late double height; // Высота блока
  late int r; // Переменная контроля красного цвета
  late int g; // Переменная контроля зеленого цвета
  late int b; // Переменная контроля синего цвета
  late int a; // Переменная контроля прозрачности цвета
  late int counter; // Счетчик

  late double borderRadius; // Радиус закругления углов
  late Color color; // Цвет блока
  int milliseconds = 1000; // Время анимации изменения блока

  String? text = ""; //Переменная для анимированного текста

  double opacity = 0;

  Queue queue = Queue();

  static AudioPlayer audioPlayer = AudioPlayer();
  static AudioCache audioCache = AudioCache(fixedPlayer: audioPlayer);

  //Увеличение счетчика
  void increment() {
    counter++;
  }

  //Изменение цвета
  void colorChange() {
    r = rnd.nextInt(255);
    g = rnd.nextInt(255);
    b = rnd.nextInt(255);
    a = rnd.nextInt(255 - 50) + 50;

    color = Color.fromARGB(a, r, g, b);
  }

  //Изменение ширины, высоты и радиуса
  void formChange() {
    width = rnd.nextDouble() * (MediaQuery.of(context).size.width - 15) + 15;
    height = rnd.nextDouble() * (MediaQuery.of(context).size.height - 15) + 15;
    borderRadius = rnd.nextDouble() * 50;
  }

  //Изменение блока по нажатию
  void nextBlock() async {
    setState(() {
      increment();
      formChange();
      colorChange();
    });
    saveMyData();
    checkForText();
    BGmusic();
  }

  void volumeChange(bool isOn) { // Функция плавного повышения и понижения громкости
    int count = 0;
    Timer.periodic(const Duration(milliseconds: 30), (timer) {
      count++;
      isOn ? audioPlayer.setVolume(1 - count / 100) :
      audioPlayer.setVolume(count / 100);
      if (count > 99){
        timer.cancel();
        isOn ? audioPlayer.stop() :
            null
        ;
      }
    });
  }

  void BGmusic() { // Включение определенных мелодий, зависящее от счетчика
    if (counter == 10) {
      volumeChange(false);
      audioCache.loop('audio/2.mp3');
    }
    if (counter == 100) {
      volumeChange(true);
    }
  }

  void opacityChange() {
    setState(() {
      opacity = opacity == 0.0 ? 1.0 : 0.0;
    });
  }

  void listener() {
    // ignore: unused_local_variable
    Timer timer =
        Timer.periodic(const Duration(milliseconds: 3800), (Timer timer) async {
      if (queue.isNotEmpty) {
        setState(() {
          text = textByCounter[queue.first];
          queue.removeFirst();
          opacityChange();
        });
        await Future.delayed(const Duration(milliseconds: 3400))
            .then((value) => opacityChange());
        await Future.delayed(const Duration(milliseconds: 400));
      }
    });
  }

  checkForText() {
    if (textByCounter[counter] != null) {
      texts.add(textByCounter[counter]!);
      queue.add(counter);
    }
  }

  //Кэширование данных
  void saveMyData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    await preferences.setInt("counter", counter);

    await preferences.setDouble("width", width);
    await preferences.setDouble("height", height);

    await preferences.setInt("counter", counter);

    await preferences.setInt("r", r);
    await preferences.setInt("g", g);
    await preferences.setInt("b", b);
    await preferences.setInt("a", a);

    await preferences.setDouble("borderRadius", borderRadius);

    await preferences.setStringList('texts', texts);
  }

  //Загрузка данных из кэша
  loadMyData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      counter = preferences.getInt("counter") ?? 0;
      width = preferences.getDouble("width") ?? 15;
      height = preferences.getDouble("height") ?? 15;

      r = preferences.getInt("r") ?? 0;
      g = preferences.getInt("g") ?? 0;
      b = preferences.getInt("b") ?? 0;
      a = preferences.getInt("a") ?? 255;

      borderRadius = preferences.getDouble("borderRadius") ?? 0;
      color = Color.fromARGB(a, r, g, b);

      texts = preferences.getStringList('texts') ?? [];
    });
  }

  @override
  void initState() {
    loadMyData();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    super.initState();
    listener();
    // player.loop('audio/background.mp3');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(children: [
        GestureDetector(
          onTap: nextBlock,
          child: Center(
            child: AnimatedContainer(
              height: height,
              width: width,
              duration: Duration(milliseconds: milliseconds),
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(borderRadius)),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Text('$counter',
              style: GoogleFonts.poiretOne(fontSize: 30, color: textColor)),
        ),
        Align(
          alignment: const Alignment(0, 0.8),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: opacity,
            child: Text(
              text!,
              style: GoogleFonts.poiretOne(fontSize: 30, color: textColor),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: const Icon(Icons.message),
            onPressed: () => Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => const Journal()),
            ),
          ),
        )
      ]),
    );
  }
}

class Journal extends StatefulWidget {
  const Journal({Key? key}) : super(key: key);

  @override
  State<Journal> createState() => _JournalState();
}

class _JournalState extends State<Journal> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(children: [
        ListView.separated(
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(),
            itemCount: texts.length,
            itemBuilder: (context, index) => ListTile(
                  title: Text(texts[texts.length - index - 1],
                      style: GoogleFonts.poiretOne(
                          fontSize: 20, color: textColor)),
                )),
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: Icon(Icons.arrow_forward_rounded, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ]),
    );
  }
}
