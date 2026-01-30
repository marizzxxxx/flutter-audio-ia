import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audios/classificador_audio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Classificação de Áudios',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Classificação de Áudios'),
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
  final String start = "Iniciar captura de áudio";
  final String stop = "Parar captura de áudio";

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final ClassificadorAudio _classificadorAudio = ClassificadorAudio();

  bool _isRecorderReady = false;
  bool _isRecording = false;

  String comandoAtual = 'desligado';

  @override
  void initState() {
    super.initState();
    initRecorder();
  }

  Future<void> initRecorder() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
    await _classificadorAudio.loadModel();
    _isRecorderReady = true;
    setState(() {});
  }

  Future<void> startRecording() async {
    if (!_isRecorderReady) return;

    await _recorder.startRecorder(
      toFile: 'audio_temp.wav',
      codec: Codec.pcm16WAV,
      sampleRate: 16000,
      numChannels: 1,
    );

    setState(() {
      _isRecording = true;
    });
  }

  Future<void> stopRecording() async {
    if (!_isRecorderReady) return;

    final path = await _recorder.stopRecorder();

    setState(() {
      _isRecording = false;
    });

    final comando =
    await _classificadorAudio.classificarAudio(path.toString());

    setState(() {
      comandoAtual = comando;
    });
  }

  String getImagemComando() {
    switch (comandoAtual) {
      case 'baixo':
        return 'assets/images/baixo.png';
      case 'cima':
        return 'assets/images/cima.png';
      case 'direito':
        return 'assets/images/direito.png';
      case 'esquerdo':
        return 'assets/images/esquerdo.png';
      case 'ligado':
        return 'assets/images/ligado.png';
      case 'desligado':
      default:
        return 'assets/images/desligado.png';
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Comando reconhecido:',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(
              comandoAtual,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Image.asset(
              getImagemComando(),
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: () async {
                if (_isRecording) {
                  await stopRecording();
                } else {
                  await startRecording();
                }
              },
              label: Text(_isRecording ? stop : start),
              icon: const Icon(Icons.mic),
            ),
          ],
        ),
      ),
    );
  }
}
