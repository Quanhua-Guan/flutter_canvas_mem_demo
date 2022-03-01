import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class DrawPage extends StatefulWidget {
  @override
  _DrawPageState createState() => _DrawPageState();
}

class _DrawPageState extends State<DrawPage> {
  final ImagePicker _picker = ImagePicker();
  ui.Image? image;

  drawImage() async {
    final imageFile =
        await _picker.getImage(source: ImageSource.gallery, imageQuality: 100);
    if (imageFile == null) {
      return;
    }
    Uint8List bytes = await imageFile.readAsBytes();

    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      return completer.complete(img);
    });
    final img = await completer.future;
    // img.dispose();
    image?.dispose();
    image = img;

    setState(() {});
  }

  @override
  void dispose() {
    image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: 375,
            height: 375,
            child: image == null
                ? null
                : RepaintBoundary(
                    child: ClipRect(
                      child: CustomPaint(
                        painter: MyPainter(image!),
                        size: Size(375, 375),
                        // child: Container(
                        //   width: 50,
                        //   height: 50,
                        //   color: Colors.green,
                        // ),
                      ),
                    ),
                  ),
          ),
          Container(
            height: 100,
            child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Close')),
          ),
          Expanded(
            child: Center(
              child: TextButton(
                  onPressed: () {
                    drawImage();
                  },
                  child: Text('addImage')),
            ),
          ),
        ],
      ),
    );
  }
}

int i = 0;

class MyPainter extends CustomPainter {
  final ui.Image pickImage;

  MyPainter(this.pickImage);

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    print(i);
    i++;
    final color = i % 3 == 0
        ? Colors.blueAccent
        : (i % 3 == 1 ? Colors.redAccent : Colors.yellowAccent);
    canvas.drawColor(color, BlendMode.srcOver);
    // canvas.saveLayer(
    //     Rect.fromLTWH(0, 0, size.width, size.height),
    //     Paint()
    //       ..invertColors = false
    //       ..isAntiAlias = false
    //       ..blendMode = ui.BlendMode.srcOver);
    // mark: -- 不会泄漏，进入页面 100M，选图绘制涨到 300，关闭页面正常回落。
    // paintImage(
    //     canvas: canvas,
    //     rect: ui.Rect.fromLTWH(
    //         0, 0, size.width.toDouble(), size.height.toDouble()),
    //     image: pickImage);
    // mark: --  不会泄漏，进入页面 100M，选图绘制涨到 300，关闭页面正常回落。
    // canvas.drawImageRect(
    //     pickImage,
    //     ui.Rect.fromLTWH(
    //         0, 0, pickImage.width.toDouble(), pickImage.height.toDouble()),
    //     ui.Rect.fromLTWH(0, 0, size.width, size.height),
    //     Paint()
    //       ..invertColors = false
    //       ..isAntiAlias = false);
    // MARK: -- 第一次进入并选图绘制内存涨到 500 M，关闭页面回到 300M。第二次进入并选图绘制，内存保持在 300M，关闭页面内存不回落；
    // 第三次使用方法一进入并选图绘制，内存涨到500，关闭页面回落到 300M。
    // canvas.drawImageRect(
    //     pickImage,
    //     ui.Rect.fromLTWH(
    //         0, 0, pickImage.width.toDouble(), pickImage.height.toDouble()),
    //     ui.Rect.fromLTWH(0, 0, size.width, size.height),
    //     Paint()..invertColors = false);
    // MARK: -- 第一次进入并选图绘制内存涨到 300 M，关闭页面不回落。第二次进入并选图绘制，内存涨到在 500M，关闭页面内存回落到 300；

    canvas.drawImageRect(
        pickImage,
        ui.Rect.fromLTWH(
            0, 0, pickImage.width.toDouble(), pickImage.height.toDouble()),
        ui.Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
        Paint()
          ..invertColors = false
          ..isAntiAlias = false
          ..blendMode = ui.BlendMode.srcATop);

    // 从上面可以看出，isAntiAlias，blendMode 会导致泄漏，我改动了 paintImage 内部的代码，把 blendMode 设置为 srcATop，泄漏发生。

    // canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return (oldDelegate as MyPainter).pickImage != pickImage;
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  Uint8List? imageMemory;

  void _incrementCounter() async {
    // RendererBinding.instance?.pipelineOwner.requestVisualUpdate();

    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return DrawPage();
    }));
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
            (imageMemory != null)
                ? Image.memory(
                    imageMemory!,
                    width: 400,
                    height: 400,
                    fit: BoxFit.fitWidth,
                  )
                : Container(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
