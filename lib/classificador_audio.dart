import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

class ClassificadorAudio {
  late Interpreter _interpreter;
  bool _isModelLoaded = false;

  final List<String> labels = [
    'baixo',
    'background',
    'cima',
    'desligado',
    'direito',
    'esquerdo',
    'ligado',
  ];

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/models/audio.tflite');
    _isModelLoaded = true;
  }

  Future<String> classificarAudio(String audioPath) async {
    if (!_isModelLoaded) {
      await loadModel();
    }

    final bytes = await File(audioPath).readAsBytes();

    // remove header WAV (44 bytes)
    final pcmBytes = bytes.sublist(44);

    final byteData = ByteData.sublistView(pcmBytes);
    final numSamples = pcmBytes.length ~/ 2;

    const int tamanhoEsperado = 44032;
    Float32List inputBuffer = Float32List(tamanhoEsperado);

    for (int i = 0; i < tamanhoEsperado; i++) {
      if (i < numSamples) {
        final sample = byteData.getInt16(i * 2, Endian.little);
        inputBuffer[i] = sample / 32768.0;
      } else {
        inputBuffer[i] = 0.0;
      }
    }

    final input = inputBuffer.reshape([1, tamanhoEsperado]);
    final output = List.filled(7, 0.0).reshape([1, 7]);

    _interpreter.run(input, output);

    final scores = output[0] as List<double>;

    int maxIndex = 0;
    double maxScore = scores[0];

    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIndex = i;
      }
    }

    return labels[maxIndex];
  }
}