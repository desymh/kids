import 'package:flutter/material.dart';

class BabData {
  final int no;
  final String judul;
  final String deskripsi;
  final double progress;
  final Color color;
  final String iconUrl;
  const BabData(this.no, this.judul, this.deskripsi, this.progress, this.color, this.iconUrl);
}

class PulauData {
  final int no;
  final String nama;
  final bool unlocked;
  final bool active;
  final int stars;
  final Color gradientStart;
  final Color gradientEnd;
  bool get completed => stars > 0;
  const PulauData(this.no, this.nama, this.unlocked, this.active, this.stars, this.gradientStart, this.gradientEnd);
}

class BadgeData {
  final String title;
  final bool unlocked;
  final Color rimColor;
  final Color innerColor;
  final Color ribbonColor;
  const BadgeData(this.title, this.unlocked, this.rimColor, this.innerColor, this.ribbonColor);
}

class StageData {
  final int no;
  final String title;
  final String imageUrl;
  final bool unlocked;
  final bool completed;
  final int stars;
  final String difficulty;
  final Color difficultyColor;
  bool get active => unlocked && !completed;
  bool get locked => !unlocked;
  const StageData(this.no, this.title, this.imageUrl, this.unlocked, this.completed, this.stars, this.difficulty, this.difficultyColor);
}