import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Generates four of the bundled sound effects as 16-bit mono WAV files.
///
/// These are synthesised here from sine waves and filtered noise, so they are
/// original CC0 content (see ASSETS_LICENSE.md) and the repo stays fully
/// offline. Run from the repo root:
///
///     dart run tool/generate_sfx.dart
///
/// Output is deterministic (fixed noise seed), so re-running it produces the
/// same bytes.
///
/// `assets/audio/pour.wav` is **not** generated here: it is a trimmed excerpt of
/// a public-domain recording of water being poured (source and processing are
/// documented in ASSETS_LICENSE.md).
void main() {
  const rate = 44100;

  writeWav('select', _select(rate));
  writeWav('error', _error(rate));
  writeWav('complete_tube', _completeTube(rate));
  writeWav('win', _win(rate));
}

const int _twoPi = 2;

List<double> _select(int rate) {
  final n = (rate * 0.13).round();
  final out = List<double>.filled(n, 0);
  for (var i = 0; i < n; i++) {
    final t = i / rate;
    final envelope = exp(-t * 30);
    out[i] = sin(_twoPi * pi * 880 * t) * envelope * 0.6;
  }
  return out;
}

List<double> _error(int rate) {
  final n = (rate * 0.26).round();
  final out = List<double>.filled(n, 0);
  var phase = 0.0;
  for (var i = 0; i < n; i++) {
    final t = i / rate;
    // Glide down from ~220 Hz to ~150 Hz for a low "nope" buzz.
    final freq = 220 - 70 * (t / 0.26);
    phase += _twoPi * pi * freq / rate;
    final envelope = exp(-t * 8) * (1 - exp(-t * 120));
    out[i] = (sin(phase) * 0.75 + sin(phase * 0.5) * 0.25) * envelope;
  }
  return out;
}

List<double> _completeTube(int rate) {
  const duration = 0.45;
  final n = (rate * duration).round();
  final out = List<double>.filled(n, 0);
  // Two quick chime notes (E6 then A6) with a soft harmonic.
  const notes = [(0.0, 1318.5), (0.14, 1760.0)];
  for (var i = 0; i < n; i++) {
    final t = i / rate;
    var sample = 0.0;
    for (final note in notes) {
      final local = t - note.$1;
      if (local < 0) continue;
      final envelope = exp(-local * 9) * (1 - exp(-local * 300));
      sample += sin(_twoPi * pi * note.$2 * local) * envelope * 0.45;
      sample += sin(_twoPi * pi * note.$2 * 2 * local) * envelope * 0.08;
    }
    out[i] = sample;
  }
  return out;
}

List<double> _win(int rate) {
  const duration = 1.7;
  final n = (rate * duration).round();
  final out = List<double>.filled(n, 0);
  // C major arpeggio: C5, E5, G5, C6, E6.
  const notes = [523.25, 659.25, 783.99, 1046.5, 1318.5];
  for (var i = 0; i < n; i++) {
    final t = i / rate;
    var sample = 0.0;
    for (var k = 0; k < notes.length; k++) {
      final local = t - k * 0.14;
      if (local < 0) continue;
      final envelope = exp(-local * 3.2) * (1 - exp(-local * 200));
      sample += sin(_twoPi * pi * notes[k] * local) * envelope * 0.32;
      sample += sin(_twoPi * pi * notes[k] * 2 * local) * envelope * 0.05;
    }
    final fade = t > duration - 0.25 ? (duration - t) / 0.25 : 1.0;
    out[i] = sample * fade.clamp(0.0, 1.0);
  }
  return out;
}

/// Writes [samples] (range about -1..1) as a normalised 16-bit PCM WAV file.
void writeWav(String name, List<double> samples) {
  const rate = 44100;
  var peak = 0.0;
  for (final s in samples) {
    peak = max(peak, s.abs());
  }
  final gain = peak == 0 ? 0.0 : 0.85 / peak;

  final data = ByteData(44 + samples.length * 2);
  void ascii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      data.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little); // fmt chunk size
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little); // byte rate
  data.setUint16(32, 2, Endian.little); // block align
  data.setUint16(34, 16, Endian.little); // bits per sample
  ascii(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);

  for (var i = 0; i < samples.length; i++) {
    final value = (samples[i] * gain * 32767).round().clamp(-32768, 32767);
    data.setInt16(44 + i * 2, value, Endian.little);
  }

  final file = File('assets/audio/$name.wav');
  file.writeAsBytesSync(data.buffer.asUint8List());
  stdout.writeln(
    '${file.path}  ${(samples.length * 2 / 1024).toStringAsFixed(1)} KiB',
  );
}
